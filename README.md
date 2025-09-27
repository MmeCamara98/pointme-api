
# PointMe API

## Présentation

PointMe API est une application Laravel destinée à la gestion des présences, des stagiaires et des coachs, avec une interface d’administration basée sur Filament. Elle propose des endpoints d’authentification (inscription, connexion) pour les stagiaires et coachs, ainsi qu’un panel d’administration moderne.

## Fonctionnalités principales
- Authentification JWT pour stagiaires et coachs
- Gestion des stagiaires et coachs (CRUD)
- Gestion des pointages, sanctions, QR tokens
- Interface d’administration Filament (gestion, visualisation, exports)
- API RESTful pour l’intégration avec des applications externes

## Structure du projet
```
point-me/
├── app/
│   ├── Http/Controllers/         # Contrôleurs API et Filament
│   ├── Models/                   # Modèles Eloquent (Stagiaire, Coach, User...)
│   └── Filament/                 # Pages et ressources Filament
├── config/                       # Fichiers de configuration (auth, jwt, etc.)
├── database/                     # Migrations, seeders, factories
├── public/                       # Fichiers accessibles publiquement
├── resources/views/              # Vues Blade
├── routes/
│   ├── api.php                   # Routes API
│   └── web.php                   # Routes web
├── tests/                        # Tests unitaires et fonctionnels
├── composer.json                 # Dépendances PHP
└── package.json                  # Dépendances JS (si front)
```

## Installation
1. Cloner le dépôt
2. Installer les dépendances PHP :
	 ```bash
	 composer install
	 ```
3. Copier le fichier d’environnement :
	 ```bash
	 cp .env.example .env
	 ```
4. Générer la clé d’application :
	 ```bash
	 php artisan key:generate
	 ```
5. Configurer la base de données dans `.env`
6. Lancer les migrations :
	 ```bash
	 php artisan migrate
	 ```
7. Installer les dépendances front (si besoin) :
	 ```bash
	 npm install && npm run dev
	 ```
8. Lancer le serveur :
	 ```bash
	 php artisan serve
	 ```

## Authentification API

### Stagiaire
- **Inscription** :
	- `POST /api/stagiaire/register`
	- Body JSON :
		```json
		{
			"first_name": "Jean",
			"last_name": "Dupont",
			"email": "jean.dupont@example.com",
			"phone": "770000000",
			"promotion": "2025",
			"start_date": "2025-09-01",
			"end_date": "2025-12-31",
			"password": "motdepasse",
			"password_confirmation": "motdepasse"
		}
		```
- **Connexion** :
	- `POST /api/stagiaire/login`
	- Body JSON :
		```json
		{
			"email": "jean.dupont@example.com",
			"password": "motdepasse"
		}
		```

### Coach
- **Connexion** :
	- `POST /api/coach/login`
	- Body JSON :
		```json
		{
			"email": "coach@example.com",
			"password": "motdepasse"
		}
		```

## Panel d’administration Filament
- Accès via `/admin`
- Gestion des stagiaires, coachs, pointages, sanctions, etc.

## Technologies utilisées
- Laravel
- Filament Admin
- JWT Auth (tymon/jwt-auth)
- PHP, Composer
- MySQL ou SQLite
- Livewire, Vite (pour le front)

## Commandes utiles
- Lancer le serveur : `php artisan serve`
- Lister les routes : `php artisan route:list`
- Rafraîchir la base : `php artisan migrate:fresh --seed`
- Vider le cache : `php artisan cache:clear && php artisan route:clear`

## Tests
- Lancer les tests :
	```bash
	php artisan test
	```

## Contribution
Toute contribution est la bienvenue. Forkez le projet, créez une branche, proposez une pull request.

## Licence
MIT
