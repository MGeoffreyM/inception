# Documentation Développeur — Inception (Version Française)

Ce document décrit comment un développeur peut configurer l'environnement **Inception** depuis zéro, compiler et lancer le projet, gérer les conteneurs et comprendre la persistance des données.

---

## 1. Configuration de l'Environnement depuis Zéro

### Prérequis Système
Assurez-vous que votre Machine Virtuelle Linux (Debian Bookworm recommandée) dispose des paquets suivants :
* `docker` (Docker Engine) et `docker-compose-plugin` (Docker Compose v2)
* `make`
* `git`
* Droits `sudo` (l'utilisateur courant doit faire partie du groupe `docker` : `sudo usermod -aG docker $USER`)

### Résolution des Noms de Domaine (`/etc/hosts`)
Ajoutez les domaines locaux dans `/etc/hosts` afin qu'ils pointent vers l'interface locale de la VM :
```bash
sudo sh -c 'echo "127.0.0.1 gematura.42.fr kuma.gematura.42.fr" >> /etc/hosts'
```

### Création des Fichiers de Configuration (`.env` et `secrets/`)
Les fichiers sensibles étant ignorés par Git, vous devez les créer après avoir cloné le dépôt :

1. **Créer `srcs/.env`** :
   ```ini
   LOGIN=gematura
   DOMAIN_NAME=gematura.42.fr

   # MARIADB
   SQL_DATABASE=wordpress_db
   SQL_USER=wp_user

   # WORDPRESS
   WP_ADMIN_USER=the_boss
   WP_ADMIN_EMAIL=patron@gematura.42.fr
   WP_USER=sousfifre
   WP_USER_EMAIL=sousfifre@gematura.42.fr

   # FTP
   FTP_USER=the_boss
   ```

2. **Créer le dossier `secrets/` à la racine du dépôt** :
   ```bash
   mkdir -p secrets
   echo -n "votre_mdp_db" > secrets/db_password.txt
   echo -n "votre_mdp_root_db" > secrets/root_db_password.txt
   echo -n "votre_mdp_wp_admin" > secrets/root_wp_password.txt
   echo -n "votre_mdp_wp_user" > secrets/wp_password.txt
   echo -n "votre_mdp_ftp" > secrets/ftp_password.txt
   chmod 600 secrets/*.txt
   ```

---

## 2. Architecture du Dépôt

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                        # Ignoré par Git (monté dans /run/secrets/)
└── srcs/
    ├── .env                        # Ignoré par Git
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/                # MariaDB 3306 (Dockerfile, 50-server.cnf, script.sh)
        ├── nginx/                  # NGINX 443 TLSv1.2/1.3 (Dockerfile, nginx.conf)
        ├── wordpress/              # PHP-FPM 9000 + WP-CLI + client Redis
        └── bonus/
            ├── adminer/            # Serveur PHP Adminer sur 8080
            ├── ftp/                # vsftpd sur 21 + 21100-21110
            ├── redis/              # Serveur Redis sur 6379
            ├── static_site/        # Serveur statique Node.js sur 3000
            └── uptime_kuma/        # Uptime Kuma 1.23.16 sur 3001
```

---

## 3. Construction et Lancement (Makefile & Docker Compose)

Le `Makefile` automatise la création des répertoires hôtes et l'exécution de Docker Compose :

* **`make` / `make all` / `make up`** : Crée `/home/gematura/data/{mariadb,html,uptime_kuma}` et lance `docker compose -f srcs/docker-compose.yml up -d --build`.
* **`make down`** : Arrête et supprime les conteneurs ainsi que le réseau `inception`.
* **`make clean`** : Arrête les conteneurs, supprime les images construites (`--rmi all`), les volumes (`--volumes`) et vide `/home/gematura/data/*`.
* **`make fclean`** : Exécute `clean` puis nettoie l'ensemble du cache système Docker (`docker system prune -a --volumes -f`).
* **`make re`** : Exécute `fclean` puis `all`.

---

## 4. Commandes Utiles pour Gérer les Conteneurs et Volumes

* **Reconstruire un seul service après modification** :
  ```bash
  docker compose -f srcs/docker-compose.yml up -d --build <nom_du_service>
  ```
* **Ouvrir un terminal interactif dans un conteneur** :
  ```bash
  docker exec -it <nom_du_conteneur> /bin/bash
  ```
* **Vérifier le PID 1 dans chaque conteneur** :
  ```bash
  docker exec wordpress ps aux
  docker exec mariadb ps aux
  docker exec nginx ps aux
  ```
* **Inspecter le réseau bridge `inception`** :
  ```bash
  docker network inspect srcs_inception
  ```
* **Lister et inspecter les volumes nommés Docker** :
  ```bash
  docker volume ls
  docker volume inspect srcs_mariadb_data srcs_wordpress_data srcs_uptime_kuma_data
  ```

---

## 5. Stockage et Persistance des Données

Toutes les données persistantes sont stockées sur la machine hôte dans `/home/gematura/data/` via des **volumes nommés Docker** utilisant le driver `local` avec l'option `o: bind` dans `srcs/docker-compose.yml` :

1. **`mariadb_data`** :
   * **Chemin Hôte** : `/home/gematura/data/mariadb`
   * **Point de montage conteneur** : `/var/lib/mysql` (dans `mariadb`)
   * **Fonctionnement** : Au démarrage, `script.sh` vérifie si `/var/lib/mysql/${SQL_DATABASE}` existe déjà. Si oui, la création initiale est ignorée et `mariadbd` démarre directement avec les tables existantes.

2. **`wordpress_data`** :
   * **Chemin Hôte** : `/home/gematura/data/html`
   * **Point de montage conteneur** : `/var/www/html` (partagé entre `wordpress`, `nginx` et `ftp`)
   * **Fonctionnement** : Au démarrage, `script.sh` vérifie si `wp-config.php` existe. S'il est déjà présent, l'installation `wp-cli` est ignorée et `php-fpm` est lancé directement en premier plan.

3. **`uptime_kuma_data`** :
   * **Chemin Hôte** : `/home/gematura/data/uptime_kuma`
   * **Point de montage conteneur** : `/app/data` (dans `uptime_kuma`)
   * **Fonctionnement** : Conserve la base de données SQLite (`kuma.db`) et l'historique des sondes Uptime Kuma entre les redémarrages.