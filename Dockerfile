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

# Copier l'application Laravel
COPY . /var/www/html/

# Définir DocumentRoot sur public/
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/apache2.conf

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Installer les dépendances
RUN composer install --optimize-autoloader --no-scripts --no-interaction

# Configurer les permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

WORKDIR /var/www/html

# Exposer le port 8080
EXPOSE 8080

# Lancer Apache
CMD ["apache2-foreground"]
