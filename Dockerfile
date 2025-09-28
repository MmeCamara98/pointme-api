FROM php:8.2-apache

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

# Configurer Apache pour Laravel
COPY .docker/000-default.conf /etc/apache2/sites-available/000-default.conf

# Configurer les permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Générer la clé d'application
RUN php artisan key:generate

WORKDIR /var/www/html
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]