FROM php:8.3-apache

# --- Dépendances système ---
RUN apt-get update && apt-get install -y \
    libicu-dev libzip-dev libpng-dev libjpeg-dev libfreetype6-dev zip unzip git curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install intl zip pdo_mysql mysqli gd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Node.js pour compiler Vite ---
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# --- Apache configuration ---
RUN a2enmod rewrite headers

WORKDIR /var/www/html

# --- Copier fichiers Composer et Node ---
COPY composer.json composer.lock package.json package-lock.json ./

# --- Installer dépendances ---
RUN composer install --no-dev --optimize-autoloader --no-scripts --no-interaction --prefer-dist
RUN npm install

# --- Copier tout le code ---
COPY . .

# --- Compiler les assets ---
RUN npm run build

# --- Génération clé + optimisation ---
RUN php artisan key:generate --force || true
RUN php artisan storage:link || true
RUN php artisan config:cache || true
RUN php artisan route:cache || true
RUN php artisan view:cache || true

# --- Permissions ---
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 775 storage bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]
