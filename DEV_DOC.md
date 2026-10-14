# Developer Documentation — Inception

**🇫🇷 [Version Française](doc/DEV_DOC_FR.md)**

This document provides technical instructions for developers to set up the **Inception** environment from scratch, understand its architecture, build and debug containers, and manage persistent storage.

---

## 1. Environment Setup from Scratch

### System Prerequisites
Ensure your Linux Virtual Machine (Debian Bookworm recommended) has the following packages installed:
* `docker` (Docker Engine) and `docker-compose-plugin` (Docker Compose v2)
* `make`
* `git`
* `sudo` privileges (your user should belong to the `docker` group: `sudo usermod -aG docker $USER`)

### Domain Resolution (`/etc/hosts`)
Add the local domain mappings to `/etc/hosts` so the host browser and CLI tools resolve the virtual hosts to the local loopback interface:
```bash
sudo sh -c 'echo "127.0.0.1 gematura.42.fr kuma.gematura.42.fr" >> /etc/hosts'
```

### Creating Configuration Files (`.env` and `secrets/`)
Because sensitive files must never be committed to Git, you must create them after cloning the repository:

1. **Create `srcs/.env`**:
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

2. **Create the `secrets/` directory at the repository root**:
   ```bash
   mkdir -p secrets
   echo -n "your_db_pass" > secrets/db_password.txt
   echo -n "your_root_db_pass" > secrets/root_db_password.txt
   echo -n "your_wp_admin_pass" > secrets/root_wp_password.txt
   echo -n "your_wp_user_pass" > secrets/wp_password.txt
   echo -n "your_ftp_pass" > secrets/ftp_password.txt
   chmod 600 secrets/*.txt
   ```

---

## 2. Repository Structure

```text
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                        # Ignored by Git (mounted at /run/secrets/)
└── srcs/
    ├── .env                        # Ignored by Git
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/                # MariaDB 3306 (Dockerfile, 50-server.cnf, script.sh)
        ├── nginx/                  # NGINX 443 TLSv1.2/1.3 (Dockerfile, nginx.conf)
        ├── wordpress/              # PHP-FPM 9000 + WP-CLI + Redis client
        └── bonus/
            ├── adminer/            # Adminer PHP server on 8080
            ├── ftp/                # vsftpd on 21 + 21100-21110
            ├── redis/              # Redis server on 6379
            ├── static_site/        # Node.js static server on 3000
            └── uptime_kuma/        # Uptime Kuma 1.23.16 on 3001
```

---

## 3. Building and Launching with Makefile & Docker Compose

The `Makefile` wraps Docker Compose commands and ensures host directories exist before mounting volumes:

* **`make` / `make all` / `make up`**:
  Creates `/home/gematura/data/{mariadb,html,uptime_kuma}` and runs:
  ```bash
  docker compose -f srcs/docker-compose.yml up -d --build
  ```
* **`make down`**:
  Stops and removes containers and the `inception` bridge network:
  ```bash
  docker compose -f srcs/docker-compose.yml down
  ```
* **`make clean`**:
  Stops containers, removes all built images (`--rmi all`) and Docker volumes (`--volumes`), and deletes the contents of `/home/gematura/data/*`.
* **`make fclean`**:
  Runs `clean` followed by `docker system prune -a --volumes -f`.
* **`make re`**:
  Executes `fclean` then `all` for a clean rebuild.

---

## 4. Useful Commands to Manage Containers, Networks, and Volumes

* **Rebuild a single service after modifying its Dockerfile or script**:
  ```bash
  docker compose -f srcs/docker-compose.yml up -d --build <service_name>
  ```
* **Open an interactive shell inside a running container**:
  ```bash
  docker exec -it <container_name> /bin/bash
  ```
* **Verify that each container runs its daemon as PID 1**:
  ```bash
  docker exec wordpress ps aux
  docker exec mariadb ps aux
  docker exec nginx ps aux
  ```
* **Inspect the isolated bridge network (`inception`)**:
  ```bash
  docker network inspect srcs_inception
  ```
* **List and inspect Docker named volumes**:
  ```bash
  docker volume ls
  docker volume inspect srcs_mariadb_data srcs_wordpress_data srcs_uptime_kuma_data
  ```

---

## 5. Data Storage and Persistence Mechanism

All persistent data is stored on the host machine inside `/home/gematura/data/` using **Docker named volumes** configured with the `local` driver and `bind` options in `srcs/docker-compose.yml`:

1. **`mariadb_data`**:
   * **Host Path**: `/home/gematura/data/mariadb`
   * **Container Mount Point**: `/var/lib/mysql` (inside `mariadb`)
   * **Persistence Logic**: On start, `srcs/requirements/mariadb/tools/script.sh` checks if `/var/lib/mysql/${SQL_DATABASE}` already exists. If it does, database initialization is skipped and `mariadbd` starts directly with the existing tables.

2. **`wordpress_data`**:
   * **Host Path**: `/home/gematura/data/html`
   * **Container Mount Point**: `/var/www/html` (shared between `wordpress`, `nginx`, and `ftp`)
   * **Persistence Logic**: On start, `srcs/requirements/wordpress/tools/script.sh` checks for the presence of `wp-config.php`. If present, `wp-cli` installation is skipped and `php-fpm` starts immediately.

3. **`uptime_kuma_data`**:
   * **Host Path**: `/home/gematura/data/uptime_kuma`
   * **Container Mount Point**: `/app/data` (inside `uptime_kuma`)
   * **Persistence Logic**: Stores Uptime Kuma's SQLite database (`kuma.db`) and monitoring history across container restarts.