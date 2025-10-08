# ================================================================
# 🐳 IMAGE DE BASE : PHP 8.3 + Apache
# ================================================================
FROM php:8.3-apache

# ================================================================
# 🧩 INSTALLATION DES DÉPENDANCES SYSTÈME ET EXTENSIONS PHP
# ================================================================
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    zip \
    unzip \
    git \
    curl \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install intl zip pdo_mysql mysqli gd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# ================================================================
# ⚙️ CONFIGURATION D'APACHE
# ================================================================
RUN a2enmod rewrite headers

# Configuration du VirtualHost Apache
RUN echo '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html/public\n\
\n\
    <Directory /var/www/html/public>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Autoriser .htaccess globalement
RUN echo '<Directory /var/www/html>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# ================================================================
# 📦 INSTALLATION DE COMPOSER
# ================================================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ================================================================
# 🚀 CONFIGURATION DU PROJET LARAVEL
# ================================================================
WORKDIR /var/www/html

# Copier les fichiers composer pour utiliser le cache Docker
COPY composer.json composer.lock ./

# Installer les dépendances PHP sans scripts
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Copier tout le projet
COPY . .

# ================================================================
# 🗂️ CRÉATION DES DOSSIERS NÉCESSAIRES
# ================================================================
RUN mkdir -p storage/logs \
 && mkdir -p storage/framework/cache/data \
 && mkdir -p storage/framework/sessions \
 && mkdir -p storage/framework/views \
 && mkdir -p storage/framework/testing \
 && mkdir -p storage/app/public \
 && mkdir -p bootstrap/cache \
 && touch storage/logs/laravel.log

# ================================================================
# 🔐 PERMISSIONS (AVANT toute commande artisan)
# ================================================================
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 775 /var/www/html/storage \
 && chmod -R 775 /var/www/html/bootstrap/cache

# ================================================================
# 🏁 SCRIPT DE DÉMARRAGE AMÉLIORÉ AVEC MIGRATIONS
# ================================================================
RUN printf '#!/bin/bash\n\
set -e\n\
\n\
echo "================================"\n\
echo "🚀 Démarrage Laravel Application"\n\
echo "================================"\n\
\n\
# Créer les dossiers\n\
echo "📁 Vérification des dossiers..."\n\
mkdir -p storage/logs\n\
mkdir -p storage/framework/{cache/data,sessions,views,testing}\n\
mkdir -p storage/app/public\n\
mkdir -p bootstrap/cache\n\
touch storage/logs/laravel.log\n\
\n\
# Permissions\n\
echo "🔐 Application des permissions..."\n\
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache\n\
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache\n\
\n\
# Copier .env.example si .env manque\n\
if [ ! -f .env ]; then\n\
  echo "📝 Création du fichier .env..."\n\
  cp .env.example .env 2>/dev/null || echo "APP_KEY=" > .env\n\
fi\n\
\n\
# Vérifier APP_KEY et la générer si nécessaire\n\
if [ -z "$APP_KEY" ] || [ "$APP_KEY" = "" ]; then\n\
  echo "⚠️  APP_KEY manquante, génération..."\n\
  php artisan key:generate --force --no-interaction 2>/dev/null || echo "Erreur génération clé"\n\
else\n\
  echo "✅ APP_KEY présente: ${APP_KEY:0:20}..."\n\
fi\n\
\n\
# Créer le lien storage\n\
if [ ! -L public/storage ]; then\n\
  echo "🔗 Création du lien symbolique storage..."\n\
  php artisan storage:link --force 2>/dev/null || echo "Lien storage déjà existant"\n\
fi\n\
\n\
# Attendre que la base de données soit prête\n\
echo "⏳ Attente de la base de données..."\n\
MAX_TRIES=30\n\
COUNT=0\n\
until php artisan migrate:status 2>/dev/null || [ $COUNT -eq $MAX_TRIES ]; do\n\
  echo "   Tentative $((COUNT+1))/$MAX_TRIES..."\n\
  COUNT=$((COUNT+1))\n\
  sleep 2\n\
done\n\
\n\
if [ $COUNT -eq $MAX_TRIES ]; then\n\
  echo "⚠️  Base de données non accessible après $MAX_TRIES tentatives"\n\
  echo "   Démarrage sans migrations..."\n\
else\n\
  echo "✅ Base de données accessible !"\n\
  \n\
  # Créer les tables de session et cache\n\
  echo "📊 Création des tables session et cache..."\n\
  php artisan session:table 2>/dev/null || echo "   Table sessions existe déjà"\n\
  php artisan cache:table 2>/dev/null || echo "   Table cache existe déjà"\n\
  \n\
  # Exécuter les migrations\n\
  echo "🗄️  Exécution des migrations..."\n\
  php artisan migrate --force 2>/dev/null || echo "   Migrations déjà effectuées"\n\
fi\n\
\n\
# Publier assets Filament si disponible\n\
if [ -d "vendor/filament" ]; then\n\
  echo "📦 Publication des assets Filament..."\n\
  php artisan vendor:publish --tag=filament-assets --force 2>/dev/null || true\n\
  php artisan filament:optimize 2>/dev/null || true\n\
fi\n\
\n\
# Gestion des caches selon environnement\n\
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ] || [ "$APP_DEBUG" = "true" ]; then\n\
  echo "🔧 Mode développement - Nettoyage des caches..."\n\
  php artisan config:clear 2>/dev/null || true\n\
  php artisan route:clear 2>/dev/null || true\n\
  php artisan view:clear 2>/dev/null || true\n\
  php artisan cache:clear 2>/dev/null || true\n\
else\n\
  echo "🚀 Mode production - Optimisation..."\n\
  php artisan config:cache 2>/dev/null || true\n\
  php artisan route:cache 2>/dev/null || true\n\
  php artisan view:cache 2>/dev/null || true\n\
fi\n\
\n\
# Afficher les informations\n\
echo "================================"\n\
echo "✅ Application prête !"\n\
echo "📍 DocumentRoot: /var/www/html/public"\n\
echo "🌐 Apache écoute sur le port 80"\n\
echo "🔑 APP_KEY: ${APP_KEY:+Définie}${APP_KEY:-Non définie}"\n\
echo "🌍 APP_URL: $APP_URL"\n\
echo "🗄️  DB_HOST: $DB_HOST"\n\
echo "================================"\n\
\n\
# Afficher la version Laravel\n\
php artisan --version 2>/dev/null || echo "Laravel version non disponible"\n\
\n\
# Démarrer Apache en premier plan\n\
echo "🌐 Démarrage Apache..."\n\
exec apache2-foreground\n\
' > /usr/local/bin/start-laravel.sh

RUN chmod +x /usr/local/bin/start-laravel.sh

# ================================================================
# ❤️ HEALTHCHECK
# ================================================================
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
 CMD curl -f http://localhost/ || exit 1

# ================================================================
# 🌐 EXPOSITION DU PORT
# ================================================================
EXPOSE 80

# ================================================================
# 🎬 POINT D'ENTRÉE
# ================================================================
CMD ["/usr/local/bin/start-laravel.sh"]

# ================================================================
# 🧾 MÉTADONNÉES
# ================================================================
LABEL maintainer="Point-Me <contact@pointme.com>" \
      description="Application Laravel Point-Me avec PHP 8.3 et Apache" \
      version="1.0"

# ================================================================
# ⚙️ VARIABLES D'ENVIRONNEMENT PAR DÉFAUT
# ================================================================
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stack \
    LOG_LEVEL=info