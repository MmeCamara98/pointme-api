FROM php:8.3-apache

# Installer extensions
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    zip unzip \
    && docker-php-ext-install intl zip pdo_mysql mysqli

# Activer mod_rewrite
RUN a2enmod rewrite

# Copier projet
COPY . /var/www/html/

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Installer dépendances
RUN composer install --optimize-autoloader --no-scripts --no-interaction

# Permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 777 /var/www/html/storage \
    && chmod -R 777 /var/www/html/bootstrap/cache

# 👇 Correction : pointer vers public/
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/apache2.conf

WORKDIR /var/www/html

EXPOSE 8080
