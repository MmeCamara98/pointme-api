FROM php:8.3-apache

# =============================================================================
# INSTALLATION DES DÉPENDANCES SYSTÈME ET EXTENSIONS PHP
# =============================================================================
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

# =============================================================================
# CONFIGURATION APACHE
# =============================================================================
RUN a2enmod rewrite headers

# Configuration VirtualHost Apache
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
    <Directory /var/www/html>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    \n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# Autoriser .htaccess
RUN echo '<Directory /var/www/html>\n\
    Options Indexes FollowSymLinks\n\
    AllowOverride All\n\
    Require all granted\n\
</Directory>' >> /etc/apache2/apache2.conf

# =============================================================================
# INSTALLATION COMPOSER
# =============================================================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# =============================================================================
# CONFIGURATION DU PROJET LARAVEL
# =============================================================================
WORKDIR /var/www/html

# Copier les fichiers composer pour optimiser le cache Docker
COPY composer.json composer.lock ./

# Installer les dépendances PHP
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Copier tout le projet
COPY . .

# =============================================================================
# CRÉATION DES DOSSIERS NÉCESSAIRES
# =============================================================================
RUN mkdir -p storage/logs \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/sessions \
    && mkdir -p storage/framework/views \
    && mkdir -p storage/framework/testing \
    && mkdir -p storage/app/public \
    && mkdir -p bootstrap/cache

# =============================================================================
# CONFIGURATION LARAVEL
# =============================================================================

# Copier .env.example vers .env si nécessaire
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Générer la clé d'application
RUN php artisan key:generate --force || echo "Clé déjà générée"

# Créer le lien symbolique storage
RUN php artisan storage:link || echo "Lien storage déjà créé"

# Vider les caches avant optimisation
RUN php artisan config:clear || true \
    && php artisan cache:clear || true \
    && php artisan route:clear || true \
    && php artisan view:clear || true

# Optimiser l'application pour la production
RUN php artisan config:cache || true \
    && php artisan route:cache || true \
    && php artisan view:cache || true

# =============================================================================
# PERMISSIONS
# =============================================================================
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && find /var/www/html/storage -type f -exec chmod 664 {} \; \
    && find /var/www/html/bootstrap/cache -type f -exec chmod 664 {} \;

# =============================================================================
# SCRIPT DE DÉMARRAGE INTÉGRÉ
# =============================================================================
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "================================"\n\
echo "🚀 Démarrage Laravel Application"\n\
echo "================================"\n\
\n\
# Créer les dossiers si nécessaire\n\
echo "📁 Vérification des dossiers..."\n\
mkdir -p storage/logs\n\
mkdir -p storage/framework/{cache/data,sessions,views,testing}\n\
mkdir -p storage/app/public\n\
mkdir -p bootstrap/cache\n\
\n\
# Appliquer les permissions\n\
echo "🔐 Application des permissions..."\n\
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache\n\
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache\n\
find /var/www/html/storage -type f -exec chmod 664 {} \\; 2>/dev/null || true\n\
find /var/www/html/bootstrap/cache -type f -exec chmod 664 {} \\; 2>/dev/null || true\n\
\n\
# Vérifier le fichier .env\n\
if [ ! -f .env ]; then\n\
    echo "📝 Création du fichier .env..."\n\
    cp .env.example .env\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Gestion selon l environnement\n\
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then\n\
    echo "🔧 Mode développement détecté"\n\
    echo "🧹 Nettoyage des caches..."\n\
    php artisan config:clear 2>/dev/null || true\n\
    php artisan route:clear 2>/dev/null || true\n\
    php artisan view:clear 2>/dev/null || true\n\
    php artisan cache:clear 2>/dev/null || true\n\
else\n\
    echo "🚀 Mode production détecté"\n\
    echo "⚡ Optimisation de l application..."\n\
    php artisan config:cache 2>/dev/null || true\n\
    php artisan route:cache 2>/dev/null || true\n\
    php artisan view:cache 2>/dev/null || true\n\
fi\n\
\n\
# Recréer le lien storage si nécessaire\n\
if [ ! -L public/storage ]; then\n\
    echo "🔗 Création du lien symbolique storage..."\n\
    php artisan storage:link 2>/dev/null || true\n\
fi\n\
\n\
# Exécuter les migrations (décommenter si besoin)\n\
# echo "🗄️  Exécution des migrations..."\n\
# php artisan migrate --force\n\
\n\
# Afficher les informations de démarrage\n\
echo "================================"\n\
echo "✅ Laravel prêt !"\n\
echo "📍 DocumentRoot: /var/www/html/public"\n\
echo "🌐 Apache listening on port 80"\n\
echo "================================"\n\
\n\
# Afficher la version de Laravel\n\
php artisan --version 2>/dev/null || true\n\
\n\
# Démarrer Apache en premier plan\n\
echo "🌐 Démarrage Apache..."\n\
exec apache2-foreground\n\
' > /usr/local/bin/start-laravel.sh

# Rendre le script exécutable
RUN chmod +x /usr/local/bin/start-laravel.sh

# =============================================================================
# HEALTHCHECK (optionnel)
# =============================================================================
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# =============================================================================
# EXPOSITION DU PORT
# =============================================================================
EXPOSE 80

# =============================================================================
# POINT D'ENTRÉE
# =============================================================================
CMD ["/usr/local/bin/start-laravel.sh"]

# =============================================================================
# INFORMATIONS SUR L'IMAGE
# =============================================================================
LABEL maintainer="Votre Nom <votre@email.com>"
LABEL description="Laravel Application avec PHP 8.3 et Apache"
LABEL version="1.0"

# =============================================================================
# VARIABLES D'ENVIRONNEMENT PAR DÉFAUT (peuvent être surchargées)
# =============================================================================
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stack \
    LOG_LEVEL=info

# =============================================================================
# INSTRUCTIONS D'UTILISATION
# =============================================================================
# 
# CONSTRUCTION DE L'IMAGE :
# docker build -t laravel-app .
#
# LANCEMENT SIMPLE (sans base de données) :
# docker run -d -p 8080:80 --name laravel laravel-app
#
# LANCEMENT AVEC DOCKER COMPOSE (recommandé) :
# Créer un fichier docker-compose.yml avec :
#
# version: '3.8'
# services:
#   app:
#     build: .
#     ports:
#       - "8080:80"
#     environment:
#       - APP_ENV=production
#       - APP_DEBUG=false
#       - DB_HOST=db
#       - DB_DATABASE=laravel
#       - DB_USERNAME=laravel
#       - DB_PASSWORD=secret
#     depends_on:
#       - db
#   db:
#     image: mysql:8.0
#     environment:
#       MYSQL_DATABASE: laravel
#       MYSQL_USER: laravel
#       MYSQL_PASSWORD: secret
#       MYSQL_ROOT_PASSWORD: root_secret
#     volumes:
#       - mysql-data:/var/lib/mysql
# volumes:
#   mysql-data:
#
# Puis lancer :
# docker-compose up -d --build
#
# ACCÉDER À L'APPLICATION :
# http://localhost:8080
#
# COMMANDES UTILES :
# docker-compose exec app php artisan migrate
# docker-compose exec app php artisan cache:clear
# docker-compose exec app php artisan config:clear
# docker-compose logs -f app
# docker-compose exec app bash
#
# CORRECTION DES PERMISSIONS EN CAS DE PROBLÈME :
# docker-compose exec app chown -R www-data:www-data storage bootstrap/cache
# docker-compose exec app chmod -R 775 storage bootstrap/cache
#
# =========================================================