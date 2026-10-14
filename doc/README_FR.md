*Ce projet a été créé dans le cadre du cursus 42 par gematura.*

# Inception (Version Française)

> **Note** : Ce fichier est la traduction française pour ta relecture personnelle. Le sujet exige que le fichier `README.md` officiel soit en anglais.

## Description

**Inception** est un projet d'administration système et de conteneurisation du cursus 42. Son objectif est de mettre en place une infrastructure web complète, sécurisée et multi-services au sein d'une Machine Virtuelle en utilisant **Docker** et **Docker Compose**.

Au lieu d'utiliser des images pré-construites provenant de DockerHub, chaque service de cette stack est construit de zéro via son propre `Dockerfile` basé sur `debian:bookworm-slim`. Chaque conteneur exécute un unique processus démon en tant que `PID 1`, communique via un réseau bridge isolé, et persiste ses données critiques sur la machine hôte grâce aux volumes nommés Docker et aux Docker secrets.

---

## Description du Projet

### Vue d'ensemble de l'infrastructure et choix de conception

Le projet est structuré dans le dossier `srcs/` et orchestré via `srcs/docker-compose.yml` ainsi qu'un `Makefile` à la racine.

#### Services Obligatoires
* **NGINX (`nginx`)** : Agit comme l'unique point d'entrée de l'infrastructure sur le port `443` uniquement, en imposant le chiffrement `TLSv1.2` et `TLSv1.3` avec un certificat auto-signé OpenSSL. Il transmet les requêtes PHP à WordPress via FastCGI (`wordpress:9000`) et agit comme reverse-proxy pour les services web bonus.
* **WordPress + PHP-FPM (`wordpress`)** : Exécute WordPress servi par PHP-FPM sur le port `9000`. Son script d'initialisation (`script.sh`) utilise `wp-cli` pour configurer automatiquement `wp-config.php`, installer WordPress, créer le compte administrateur (`the_boss`) et un second utilisateur (`sousfifre`), puis activer le cache Redis.
* **MariaDB (`mariadb`)** : Serveur de base de données relationnelle écoutant sur le port `3306` au sein du réseau interne. Il initialise la base de données WordPress et les privilèges utilisateurs lors du premier lancement à l'aide des identifiants montés via les Docker secrets.

#### Services Bonus
* **Cache Redis (`redis`)** : Base de données en mémoire écoutant sur le port `6379` (`maxmemory 256mb`, politique `allkeys-lru`) connectée à WordPress pour mettre en cache les requêtes SQL et accélérer le chargement des pages.
* **Serveur FTP (`ftp`)** : Exécute `vsftpd` sur le port `21` (avec les ports passifs `21100-21110`), permettant la gestion de fichiers à distance directement dans le volume WordPress (`/var/www/html`) sous l'identifiant `UID/GID 33` (`www-data`).
* **Site Statique (`static_site`)** : Un serveur HTTP léger en Node.js écoutant sur le port interne `3000`, servant un CV statique en HTML/CSS via le reverse-proxy NGINX à l'adresse `https://gematura.42.fr/cv/`.
* **Adminer (`adminer`)** : Interface web de gestion de base de données tournant sur le port interne `8080` et exposée de manière sécurisée derrière NGINX sur `https://gematura.42.fr/adminer/`.
* **Uptime Kuma (`uptime_kuma`)** : Outil de monitoring auto-hébergé (release `1.23.16`) tournant sur le port interne `3001` et servi via un hôte virtuel NGINX dédié avec support WebSocket sur `https://kuma.gematura.42.fr`.

### Comparaisons Techniques

#### 1. Machines Virtuelles vs Docker
* **Les Machines Virtuelles (VM)** virtualisent une pile matérielle complète (CPU, mémoire, disque, réseau) au-dessus d'un hyperviseur. Chaque VM fait tourner son propre système d'exploitation invité complet et son propre noyau, ce qui consomme beaucoup de RAM, d'espace disque et de temps de démarrage, mais offre une isolation matérielle totale.
* **Les Conteneurs Docker** virtualisent au niveau du système d'exploitation en partageant le noyau Linux de la machine hôte. Ils utilisent les *namespaces* du noyau (pour isoler les processus, le réseau et les points de montage) et les *cgroups* (pour limiter les ressources). Par conséquent, les conteneurs sont très légers, démarrent en quelques millisecondes et n'embarquent que l'application et ses dépendances.

#### 2. Secrets vs Variables d'Environnement
* **Les Variables d'Environnement (`.env`)** sont idéales pour les paramètres de configuration non sensibles (comme les noms de domaine, noms de base de données ou noms d'utilisateurs). Cependant, elles sont visibles en clair via `docker inspect` ou dans l'environnement du processus (`/proc/1/environ`), ce qui les rend non sécurisées pour les mots de passe.
* **Les Docker Secrets** stockent les données sensibles (mots de passe de la base de données, de WordPress et du FTP) dans des fichiers dédiés montés uniquement en mémoire vive (`tmpfs`) dans le conteneur sous `/run/secrets/<nom_du_secret>`. Ils ne sont jamais enregistrés dans les couches de l'image, n'apparaissent pas dans `docker inspect` et ne sont accessibles qu'aux conteneurs explicitement autorisés dans `docker-compose.yml`.

#### 3. Réseau Docker (Bridge) vs Réseau Host
* **Le Réseau Host (`network: host`)** supprime l'isolation réseau entre le conteneur et l'hôte Docker : le conteneur partage directement l'adresse IP et les ports de l'hôte. Cela expose les services internes (comme MariaDB ou Redis) sur la machine hôte et peut créer des conflits de ports. De plus, son utilisation est formellement interdite par le sujet.
* **Le Réseau Bridge Docker (`driver: bridge`)** crée un réseau virtuel isolé (`inception`) où les conteneurs communiquent entre eux en utilisant leurs noms de services grâce au serveur DNS interne de Docker (ex. `wordpress` se connecte à `mariadb:3306` et `redis:6379`), tandis que seuls les ports explicitement publiés (`443` et `21`) sont accessibles depuis l'extérieur.

#### 4. Volumes Docker vs Bind Mounts
* **Les Bind Mounts** montent directement un chemin de fichier ou de dossier spécifique du système de fichiers hôte dans un conteneur. Ils dépendent fortement de l'arborescence de l'hôte et ne sont pas gérés par l'API de cycle de vie des volumes Docker (`docker volume ls`, `docker volume inspect`). Les bind mounts directs sont interdits par le sujet.
* **Les Volumes Nommés Docker** sont des entités de stockage gérées par Docker. Dans ce projet, nous déclarons des volumes nommés (`mariadb_data`, `wordpress_data`, `uptime_kuma_data`) utilisant le driver `local` avec `driver_opts` (`o: bind`) afin que Docker les gère comme de vrais volumes nommés tout en stockant physiquement les données persistantes dans `/home/gematura/data/` sur la machine hôte, conformément au sujet.

---

## Instructions

### Prérequis
1. Une Machine Virtuelle Linux avec **Docker Engine**, **Docker Compose**, **Make** et **Git** installés.
2. Associer les domaines du projet à l'IP locale dans `/etc/hosts` :
   ```bash
   127.0.0.1 gematura.42.fr kuma.gematura.42.fr
   ```
3. Créer le fichier `srcs/.env` et le dossier `secrets/` contenant les fichiers de mots de passe requis (`db_password.txt`, `root_db_password.txt`, `wp_password.txt`, `root_wp_password.txt`, `ftp_password.txt`). *(Voir `DEV_DOC_FR.md` pour les détails).*

### Compilation & Exécution
Utiliser le `Makefile` à la racine pour construire et gérer l'infrastructure :
* **Construire et démarrer tous les services** : `make`
* **Arrêter les conteneurs** : `make down`
* **Supprimer les conteneurs, images, volumes et données hôtes** : `make clean`
* **Nettoyage complet du système Docker** : `make fclean`
* **Tout reconstruire depuis zéro** : `make re`

---

## Ressources

### Références Classiques
* [Documentation Officielle Docker](https://docs.docker.com/)
* [Spécification Docker Compose](https://docs.docker.com/compose/compose-file/)
* [Documentation NGINX](https://nginx.org/en/docs/)
* [Référence des commandes WP-CLI](https://developer.wordpress.org/cli/commands/)
* [Base de connaissances MariaDB](https://mariadb.com/kb/en/)
* [Wiki Uptime Kuma](https://github.com/louislam/uptime-kuma/wiki)

### Utilisation de l'Intelligence Artificielle
Conformément aux directives de 42 sur l'IA, des outils d'IA ont été utilisés comme assistants d'apprentissage et de relecture pour :
* **Audit du projet et conformité au sujet** : Vérification des `Dockerfile`, `docker-compose.yml` et `nginx.conf` par rapport aux règles du sujet (gestion de `try_files` dans NGINX, chemin du volume d'Uptime Kuma).
* **Synchronisation des services** : Conception de la boucle de vérification (`redis-cli ping`) dans le script d'entrée de WordPress pour garantir que Redis est prêt avant l'activation du plugin de cache.
* **Structuration de la documentation** : Aide à la structuration et à la traduction de la documentation (`README.md`, `USER_DOC.md`, `DEV_DOC.md`).