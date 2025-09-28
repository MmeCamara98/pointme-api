#!/bin/bash

# Attendre que la base de données soit prête
sleep 10

# Générer la clé d'application si elle n'existe pas
php artisan key:generate

# Exécuter les migrations
php artisan migrate --force

# Démarrer l'application
php -S 0.0.0.0:$PORT -t public