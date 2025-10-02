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

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copier l'application Laravel
COPY . /var/www/html/

# Définir DocumentRoot sur public/
RUN sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/sites-available/000-default.conf \
    && sed -i 's|/var/www/html|/var/www/html/public|g' /etc/apache2/apache2.conf

# Installer les dépendances (PRODUCTION)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# ✅ GÉNÉRER LES CLÉS MANQUANTES
RUN php artisan key:generate --force
RUN php artisan jwt:secret --force

# ✅ CONFIGURER LE CACHE
RUN php artisan config:cache
RUN php artisan route:cache
RUN php artisan view:cache

# Configurer les permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

WORKDIR /var/www/html

# ✅ CORRIGER LE PORT (Render utilise $PORT)
EXPOSE 80

# Lancer Apache
CMD ["apache2-foreground"]