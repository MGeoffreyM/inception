# Documentation Utilisateur — Inception (Version Française)

Ce guide explique quels services sont fournis par l'infrastructure **Inception** et comment un utilisateur final ou un administrateur peut démarrer, utiliser et superviser la plateforme.

---

## 1. Présentation des Services Fournis

La stack exécute 8 services isolés orchestrés par Docker Compose :

| Service | Rôle | Mode d'accès |
| :--- | :--- | :--- |
| **NGINX** | Serveur web HTTPS sécurisé et reverse-proxy (TLSv1.2 / TLSv1.3) | Point d'entrée unique sur le port `443` |
| **WordPress** | Système de gestion de contenu (CMS) principal propulsé par PHP-FPM | `https://gematura.42.fr` |
| **MariaDB** | Base de données relationnelle stockant le contenu et les utilisateurs WordPress | Réseau interne uniquement (`3306`) |
| **Redis** | Cache d'objets en mémoire accélérant les requêtes de WordPress | Réseau interne uniquement (`6379`) |
| **Site Statique** | Serveur Node.js hébergeant un CV / site vitrine statique | `https://gematura.42.fr/cv/` |
| **Adminer** | Interface web de gestion de la base de données MariaDB | `https://gematura.42.fr/adminer/` |
| **Uptime Kuma** | Tableau de bord de supervision en temps réel des services | `https://kuma.gematura.42.fr` |
| **Serveur FTP** | Serveur `vsftpd` donnant un accès direct aux fichiers du volume WordPress | Port `21` (Passif : `21100-21110`) |

---

## 2. Démarrer et Arrêter le Projet

Toutes les opérations s'effectuent depuis la racine du dépôt avec la commande `make` :

* **Démarrer l'infrastructure** (crée les dossiers de données, construit les images si nécessaire et lance les conteneurs en arrière-plan) :
  ```bash
  make
  ```
* **Arrêter l'infrastructure** (arrête et supprime les conteneurs sans effacer vos données) :
  ```bash
  make down
  ```
* **Réinitialiser et relancer complètement le projet** (supprime les données, reconstruit les images et repart à neuf) :
  ```bash
  make re
  ```

---

## 3. Accéder au Site Web et aux Panneaux d'Administration

> **Note sur le HTTPS** : Ce projet utilisant un certificat SSL/TLS auto-signé généré avec OpenSSL, votre navigateur affichera un avertissement de sécurité lors de la première visite. Cliquez sur **« Avancé »** puis **« Accepter le risque et poursuivre »**.

1. **Site Principal WordPress** :
   * URL : `https://gematura.42.fr`
2. **Panneau d'Administration WordPress** :
   * URL : `https://gematura.42.fr/wp-admin`
   * Connectez-vous avec l'identifiant administrateur (`the_boss`) et le mot de passe contenu dans `secrets/root_wp_password.txt`.
3. **Administration Base de Données (Adminer)** :
   * URL : `https://gematura.42.fr/adminer/`
   * **Système** : `MySQL` / `MariaDB`
   * **Serveur** : `mariadb`
   * **Utilisateur** : `wp_user` (ou `root`)
   * **Mot de passe** : Mot de passe situé dans `secrets/db_password.txt`
   * **Base de données** : `wordpress_db`
4. **Site Statique (CV)** :
   * URL : `https://gematura.42.fr/cv/`
5. **Tableau de Bord Uptime Kuma** :
   * URL : `https://kuma.gematura.42.fr`
   * Lors de la première connexion, créez votre compte administrateur et ajoutez vos sondes (ex. sonde HTTPS sur `https://nginx:443` ou ping TCP sur `mariadb:3306` et `redis:6379`).
6. **Accès FTP** :
   * Connectez-vous avec un client FTP (`ftp` en ligne de commande ou FileZilla) sur l'hôte `gematura.42.fr` (ou `127.0.0.1`), port `21`, avec l'utilisateur défini dans `srcs/.env` (`FTP_USER`) et le mot de passe de `secrets/ftp_password.txt`.

---

## 4. Localiser et Gérer les Identifiants

Pour des raisons de sécurité, les identifiants sont séparés entre un fichier d'environnement non sensible et des fichiers de secrets (tous deux ignorés par Git) :

1. **Configuration non sensible (`srcs/.env`)** :
   Contient les noms d'utilisateurs, adresses e-mail, nom de la base et nom de domaine :
   * `DOMAIN_NAME=gematura.42.fr`
   * `SQL_DATABASE=wordpress_db`
   * `SQL_USER=wp_user`
   * `WP_ADMIN_USER=the_boss`
   * `WP_USER=sousfifre`
   * `FTP_USER=the_boss`

2. **Mots de passe sensibles (dossier `secrets/` à la racine du projet)** :
   Chaque mot de passe est stocké dans son propre fichier texte :
   * `secrets/root_db_password.txt` — Mot de passe `root` de MariaDB.
   * `secrets/db_password.txt` — Mot de passe de l'utilisateur SQL `wp_user`.
   * `secrets/root_wp_password.txt` — Mot de passe de l'administrateur WordPress (`the_boss`).
   * `secrets/wp_password.txt` — Mot de passe du second utilisateur WordPress (`sousfifre`).
   * `secrets/ftp_password.txt` — Mot de passe de l'utilisateur FTP.

---

## 5. Vérifier le Bon Fonctionnement des Services

* **Vérifier l'état des conteneurs** :
  ```bash
  docker compose -f srcs/docker-compose.yml ps
  ```
  Les 8 conteneurs doivent afficher le statut `Up`.

* **Consulter les journaux (logs) d'un service** :
  ```bash
  docker logs wordpress
  docker logs mariadb
  docker logs nginx
  ```

* **Tester la réponse HTTPS et le certificat TLS** :
  ```bash
  curl -Ik https://gematura.42.fr
  ```

* **Vérifier l'état du cache Redis dans WordPress** :
  ```bash
  docker exec wordpress wp redis status --allow-root --path=/var/www/html
  ```