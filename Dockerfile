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
# ⚙️ CONFIGURATION D’APACHE
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
 && mkdir -p storage/framework/{cache/data,sessions,views,testing} \
 && mkdir -p storage/app/public \
 && mkdir -p bootstrap/cache

# ================================================================
# 🔑 CONFIGURATION LARAVEL
# ================================================================
RUN if [ ! -f .env ]; then cp .env.example .env; fi
RUN php artisan key:generate --force || echo "Clé déjà générée"
RUN php artisan storage:link || echo "Lien storage déjà créé"

# Nettoyer les caches avant optimisation
RUN php artisan config:clear || true \
 && php artisan cache:clear || true \
 && php artisan route:clear || true \
 && php artisan view:clear || true

# Optimiser pour la production
RUN php artisan config:cache || true \
 && php artisan route:cache || true \
 && php artisan view:cache || true

# ================================================================
# 🔐 PERMISSIONS
# ================================================================
RUN chown -R www-data:www-data /var/www/html \
 && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache \
 && find /var/www/html/storage -type f -exec chmod 664 {} \; \
 && find /var/www/html/bootstrap/cache -type f -exec chmod 664 {} \;

# ================================================================
# 🏁 SCRIPT DE DÉMARRAGE
# ================================================================
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "================================"\n\
echo "🚀 Démarrage Laravel Application"\n\
echo "================================"\n\
\n\
echo "📁 Vérification des dossiers..."\n\
mkdir -p storage/logs\n\
mkdir -p storage/framework/{cache/data,sessions,views,testing}\n\
mkdir -p storage/app/public\n\
mkdir -p bootstrap/cache\n\
\n\
echo "🔐 Application des permissions..."\n\
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache\n\
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache\n\
find /var/www/html/storage -type f -exec chmod 664 {} \\; 2>/dev/null || true\n\
find /var/www/html/bootstrap/cache -type f -exec chmod 664 {} \\; 2>/dev/null || true\n\
\n\
if [ ! -f .env ]; then\n\
  echo "📝 Création du fichier .env..."\n\
  cp .env.example .env\n\
  php artisan key:generate --force\n\
fi\n\
\n\
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then\n\
  echo "🔧 Mode développement détecté"\n\
  php artisan config:clear 2>/dev/null || true\n\
  php artisan route:clear 2>/dev/null || true\n\
  php artisan view:clear 2>/dev/null || true\n\
  php artisan cache:clear 2>/dev/null || true\n\
else\n\
  echo "🚀 Mode production détecté"\n\
  php artisan config:cache 2>/dev/null || true\n\
  php artisan route:cache 2>/dev/null || true\n\
  php artisan view:cache 2>/dev/null || true\n\
fi\n\
\n\
if [ ! -L public/storage ]; then\n\
  echo "🔗 Création du lien symbolique storage..."\n\
  php artisan storage:link 2>/dev/null || true\n\
fi\n\
\n\
echo "================================"\n\
echo "✅ Laravel prêt !"\n\
echo "📍 DocumentRoot: /var/www/html/public"\n\
echo "🌐 Apache listening on port 80"\n\
echo "================================"\n\
php artisan --version 2>/dev/null || true\n\
\n\
echo "🌐 Démarrage Apache..."\n\
exec apache2-foreground\n\
' > /usr/local/bin/start-laravel.sh

RUN chmod +x /usr/local/bin/start-laravel.sh

# ================================================================
# ❤️ HEALTHCHECK (optionnel)
# ================================================================
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
 CMD curl -f http://localhost/ || exit 1

# ================================================================
# 🌐 EXPOSITION DU PORT
# ================================================================
EXPOSE 80

# ================================================================
# 🎬 POINT D’ENTRÉE
# ================================================================
CMD ["/usr/local/bin/start-laravel.sh"]

# ================================================================
# 🧾 MÉTADONNÉES
# ================================================================
LABEL maintainer="Votre Nom <votre@email.com>" \
      description="Application Laravel avec PHP 8.3 et Apache" \
      version="1.0"

# ================================================================
# ⚙️ VARIABLES D’ENVIRONNEMENT PAR DÉFAUT
# ================================================================
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stack \
    LOG_LEVEL=info
