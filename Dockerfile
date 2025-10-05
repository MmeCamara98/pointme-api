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

# Configuration Apache VirtualHost
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
    <Directory /var/www/html/public/vendor>\n\
        Options -Indexes +FollowSymLinks\n\
        AllowOverride None\n\
        Require all granted\n\
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
# INSTALLATION COMPOSER
# ============================================
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# ============================================
# CONFIGURATION DU PROJET
# ============================================
WORKDIR /var/www/html

# Copier les fichiers de dépendances en premier (pour optimiser le cache Docker)
COPY composer.json composer.lock* ./

# Installer les dépendances PHP
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist

# Copier le reste du projet
COPY . .

# ============================================
# INSTALLER NPM ET COMPILER LES ASSETS
# ============================================
# Installer les dépendances npm si package.json existe
RUN if [ -f "package.json" ]; then \
        echo "📦 Installation des dépendances npm..." && \
        npm install; \
    else \
        echo "⚠️  Pas de package.json trouvé"; \
    fi

# Compiler les assets seulement si vite.config.js existe
RUN if [ -f "vite.config.js" ]; then \
        echo "🎨 Compilation des assets avec Vite..." && \
        npm run build; \
    else \
        echo "ℹ️  Pas de Vite config, skip compilation"; \
    fi

# ============================================
# PUBLIER LES ASSETS FILAMENT
# ============================================
RUN echo "📦 Publication des assets Filament..." \
    && php artisan vendor:publish --tag=filament-assets --force 2>/dev/null || true \
    && php artisan vendor:publish --tag=filament-config --force 2>/dev/null || true \
    && php artisan vendor:publish --provider="Filament\FilamentServiceProvider" --force 2>/dev/null || true

# Optimiser Filament
RUN php artisan filament:optimize 2>/dev/null || echo "⚠️  filament:optimize non disponible"

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
# Copier .env.example vers .env si nécessaire
RUN if [ ! -f .env ]; then \
        echo "📝 Création du fichier .env..." && \
        cp .env.example .env; \
    fi

# Générer la clé d'application
RUN php artisan key:generate --force 2>/dev/null || echo "⚠️  Clé déjà générée"

# Créer le lien symbolique storage
RUN php artisan storage:link 2>/dev/null || echo "ℹ️  Lien storage déjà créé"

# Vider les caches avant optimisation
RUN php artisan config:clear 2>/dev/null || true
RUN php artisan cache:clear 2>/dev/null || true
RUN php artisan route:clear 2>/dev/null || true
RUN php artisan view:clear 2>/dev/null || true

# Optimiser pour la production
RUN php artisan config:cache 2>/dev/null || true
RUN php artisan route:cache 2>/dev/null || true
RUN php artisan view:cache 2>/dev/null || true

# ============================================
# PERMISSIONS
# ============================================
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 /var/www/html/storage \
    && chmod -R 775 /var/www/html/bootstrap/cache \
    && chmod -R 755 /var/www/html/public

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
echo "🔐 Application des permissions..."\n\
chown -R www-data:www-data storage bootstrap/cache 2>/dev/null || true\n\
chmod -R 775 storage bootstrap/cache 2>/dev/null || true\n\
\n\
# Vérifier .env\n\
if [ ! -f .env ]; then\n\
    echo "📝 Création du fichier .env..."\n\
    cp .env.example .env\n\
    php artisan key:generate --force\n\
fi\n\
\n\
# Recréer le lien storage\n\
php artisan storage:link 2>/dev/null || true\n\
\n\
# Publier les assets Filament si le dossier n existe pas\n\
if [ ! -d "public/vendor/filament" ]; then\n\
    echo "📦 Publication des assets Filament..."\n\
    php artisan vendor:publish --tag=filament-assets --force 2>/dev/null || true\n\
    php artisan filament:optimize 2>/dev/null || true\n\
fi\n\
\n\
# Gestion selon environnement\n\
if [ "$APP_ENV" = "local" ] || [ "$APP_ENV" = "development" ]; then\n\
    echo "🔧 Mode développement"\n\
    php artisan config:clear 2>/dev/null || true\n\
    php artisan cache:clear 2>/dev/null || true\n\
else\n\
    echo "🚀 Mode production"\n\
    php artisan config:cache 2>/dev/null || true\n\
    php artisan route:cache 2>/dev/null || true\n\
    php artisan view:cache 2>/dev/null || true\n\
fi\n\
\n\
echo "================================"\n\
echo "✅ Filament Laravel prêt !"\n\
echo "📍 URL: $APP_URL"\n\
echo "================================"\n\
\n\
php artisan --version 2>/dev/null || true\n\
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

# ============================================
# METADATA
# ============================================
LABEL maintainer="Your Name <your@email.com>"
LABEL description="Laravel + Filament Application with PHP 8.3 and Apache"
LABEL version="1.0"

# ============================================
# VARIABLES D'ENVIRONNEMENT PAR DÉFAUT
# ============================================
ENV APP_ENV=production \
    APP_DEBUG=false \
    LOG_CHANNEL=stack \
    LOG_LEVEL=info