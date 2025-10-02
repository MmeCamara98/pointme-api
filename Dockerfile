FROM php:8.3-apache

# Installer les extensions nécessaires
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    zip \
    unzip \
    && docker-php-ext-install \
    intl \
    zip \
    pdo_mysql \
    mysqli

# Activer Apache mod_rewrite
RUN a2enmod rewrite

# Copier l'application
COPY . /var/www/html/

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Installer les dépendances
RUN composer install --optimize-autoloader --no-scripts --no-interaction

# Configurer les permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

WORKDIR /var/www/html

EXPOSE 8080 
