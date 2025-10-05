FROM php:8.3-apache

# ============================================
# INSTALLATION DES DÉPENDANCES SYSTÈME
# ============================================
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

# ============================================
# INSTALLATION NODE.JS
# ============================================
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# ============================================
# CONFIGURATION APACHE
# ============================================
RUN a2enmod rewrite headers expires deflate

# ============================================
# INSTALLATION COMPOSER
# ============================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ============================================
# CONFIGURATION DU PROJET
# ============================================
WORKDIR /var/www/html

# Copier les fichiers de dépendances
COPY composer.json composer.lock ./
COPY package*.json ./

# Installer les dépendances PHP
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Installer les dépendances npm
RUN npm ci --omit=dev

# Copier tout le projet
COPY . .

# ============================================
# PUBLIER LES ASSETS FILAMENT
# ============================================
RUN php artisan vendor:publish --tag=filament-assets --force || true
RUN php artisan vendor:publish --tag=filament-config --force || true
RUN php artisan vendor:publish --provider="Filament\FilamentServiceProvider" --force || true

# ============================================
# COMPILER LES ASSETS
# ============================================
RUN npm run build

# Optimiser Filament
RUN php artisan filament:optimize || true

# ============================================
# CRÉER LES DOSSIERS NÉCESSAIRES
# ============================================
RUN mkdir -p storage/logs \
    && mkdir -p storage/framework/cache/data \
    && mkdir -p storage/framework/sessions \
    && mkdir -p storage/framework/views \
    && mkdir -p storage/framework/testing \
    && mkdir -p storage/app/public \
    && mkdir -p bootstrap/cache

# ============================================
# CONFIGURATION LARAVEL
# ============================================
RUN if [ ! -f .env ]; then cp .env.example .env; fi

RUN php artisan key:generate --force || echo "Clé déjà générée"

RUN php artisan storage:link || echo "Lien storage déjà créé"

# Vider les caches avant optimisation
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan route:clear || true
RUN php artisan view:clear || true

# Optimiser pour la production
RUN php artisan config:cache || true
RUN php artisan route:cache || true
RUN php artisan view:cache || true

# ============================================
# PERMISSIONS
# ============================================
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && chmod -R 755 /var/www/html/public

# ============================================
# CONFIGURATION APACHE VIRTUALHOST
# ============================================
RUN echo '<VirtualHost *:80>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html/public\n\
    \n\
    <Directory /var/www/html/public>\n\
        Options -Indexes +FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    \n\
    # Configuration pour les assets Filament\n\
    <Directory /var/www/html/public/vendor>\n\
        Options -Indexes +FollowSymLinks\n\
        AllowOverride None\n\
        Require all granted\n\
        \n\
        # Cache des assets\n\
        <IfModule mod_expires.c>\n\
            ExpiresActive On\n\
            ExpiresDefault "access plus 1 year"\n\
        </IfModule>\n\
    </Directory>\n\
    \n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# ============================================
# SCRIPT DE DÉMARRAGE
# ============================================
RUN echo '#!/bin/bash\n\
set -e\n\
\n\
echo "================================"\n\
echo "🚀 Démarrage Filament Laravel"\n\
echo "================================"\n\
\n\
# Créer les dossiers\n\
mkdir -p storage/logs storage/framework/{cache/data,sessions,views} bootstrap/cache\n\
\n\
# Permissions\n\
chown -R www-data:www-data storage bootstrap/cache\n\
chmod -R 775 storage bootstrap/cache\n\
\n\
# Vérifier .env\n\
if [ ! -f .env ]; then\n\
    cp .env.example .env\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Recréer le lien storage\n\
php artisan storage:link 2>/dev/null || true\n\
\n\
# Publier les assets Filament si nécessaire\n\
if [ ! -d "public/vendor/filament" ]; then\n\
    echo "📦 Publication des assets Filament..."\n\
    php artisan vendor:publish --tag=filament-assets --force\n\
    php artisan filament:optimize\n\
fi\n\
\n\
# Gestion selon environnement\n\
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then\n\
    echo "🔧 Mode développement"\n\
    php artisan config:clear\n\
    php artisan cache:clear\n\
else\n\
    echo "🚀 Mode production"\n\
    php artisan config:cache\n\
    php artisan route:cache\n\
    php artisan view:cache\n\
fi\n\
\n\
echo "================================"\n\
echo "✅ Filament Laravel prêt !"\n\
echo "================================"\n\
\n\
php artisan --version\n\
\n\
exec apache2-foreground\n\
' > /usr/local/bin/start-laravel.sh

RUN chmod +x /usr/local/bin/start-laravel.sh

# ============================================
# HEALTHCHECK
# ============================================
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

# ============================================
# EXPOSITION DU PORT
# ============================================
EXPOSE 80

# ============================================
# COMMANDE DE DÉMARRAGE
# ============================================
CMD ["/usr/local/bin/start-laravel.sh"]