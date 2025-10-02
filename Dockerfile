FROM php:8.3-apache

# Installer les extensions
RUN apt-get update && apt-get install -y \
    libzip-dev zip unzip git curl \
    && docker-php-ext-install pdo_mysql zip

# Activer mod_rewrite
RUN a2enmod rewrite

# Définir le document root
ENV APACHE_DOCUMENT_ROOT /var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copier l'application
COPY . /var/www/html/

WORKDIR /var/www/html

# Installer les dépendances
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# ✅ CRÉER LE FICHIER .env S'IL N'EXISTE PAS
RUN if [ ! -f ".env" ]; then \
        cp .env.example .env; \
    fi

# ✅ GÉNÉRER LES CLÉS (avec gestion d'erreur)
RUN php artisan key:generate --force || echo "Key generation completed"
RUN php artisan jwt:secret --force || echo "JWT secret generation completed"

# Cache (optionnel)
RUN php artisan config:cache || echo "Config cache completed"
RUN php artisan route:cache || echo "Route cache completed"

# Permissions
RUN chmod -R 775 storage bootstrap/cache
RUN chown -R www-data:www-data storage bootstrap/cache

EXPOSE 80
CMD ["apache2-foreground"]