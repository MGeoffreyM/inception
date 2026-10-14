# User Documentation — Inception

This guide explains what services are provided by the **Inception** infrastructure and how an end user or system administrator can operate, access, and monitor the platform.

---

## 1. Overview of Provided Services

The stack runs 8 isolated services orchestrated by Docker Compose:

| Service | Role | Access Method |
| :--- | :--- | :--- |
| **NGINX** | Secure HTTPS web server and reverse proxy (TLSv1.2 / TLSv1.3) | Entry point on port `443` |
| **WordPress** | Main Content Management System (CMS) powered by PHP-FPM | `https://gematura.42.fr` |
| **MariaDB** | Relational database storing WordPress content and users | Internal network only (`3306`) |
| **Redis** | In-memory object cache accelerating WordPress database queries | Internal network only (`6379`) |
| **Static Site** | Node.js server hosting an online CV / showcase page | `https://gematura.42.fr/cv/` |
| **Adminer** | Web-based database management interface for MariaDB | `https://gematura.42.fr/adminer/` |
| **Uptime Kuma** | Real-time monitoring dashboard for all infrastructure services | `https://kuma.gematura.42.fr` |
| **FTP Server** | `vsftpd` server providing direct file access to the WordPress volume | Port `21` (Passive: `21100-21110`) |

---

## 2. Starting and Stopping the Project

All operations are performed from the root directory of the repository using `make`:

* **Start the infrastructure** (creates data folders, builds images if needed, and starts containers in the background):
  ```bash
  make
  ```
* **Stop the infrastructure** (stops and removes containers without deleting your data):
  ```bash
  make down
  ```
* **Restart the infrastructure completely** (wipes all data, rebuilds images, and starts fresh):
  ```bash
  make re
  ```

---

## 3. Accessing the Website and Administration Panels

> **Note on HTTPS**: Because this project uses a self-signed SSL/TLS certificate generated via OpenSSL, your web browser will display a security warning on your first visit. Click **"Advanced"** and **"Accept the Risk and Continue"** to access the pages.

1. **Main WordPress Website**:
   * URL: `https://gematura.42.fr`
2. **WordPress Administration Panel**:
   * URL: `https://gematura.42.fr/wp-admin`
   * Log in using the administrator username (`the_boss`) and the password stored in `secrets/root_wp_password.txt`.
3. **Database Administration (Adminer)**:
   * URL: `https://gematura.42.fr/adminer/`
   * **System**: `MySQL` / `MariaDB`
   * **Server**: `mariadb`
   * **Username**: `wp_user` (or `root`)
   * **Password**: Password from `secrets/db_password.txt`
   * **Database**: `wordpress_db`
4. **Static Resume Website**:
   * URL: `https://gematura.42.fr/cv/`
5. **Uptime Kuma Monitoring Dashboard**:
   * URL: `https://kuma.gematura.42.fr`
   * On first visit, create your monitoring administrator account and add monitors (e.g., HTTPS monitor for `https://nginx:443` or TCP ping for `mariadb:3306` and `redis:6379`).
6. **FTP Access**:
   * Connect using an FTP client (such as `ftp` CLI or FileZilla) to host `gematura.42.fr` (or `127.0.0.1`), port `21`, using the username defined in `srcs/.env` (`FTP_USER`) and the password in `secrets/ftp_password.txt`.

---

## 4. Locating and Managing Credentials

For security reasons, credentials are split between non-sensitive configuration variables and secret files (both ignored by Git):

1. **Non-sensitive Configuration (`srcs/.env`)**:
   Contains usernames, emails, database names, and the domain name:
   * `DOMAIN_NAME=gematura.42.fr`
   * `SQL_DATABASE=wordpress_db`
   * `SQL_USER=wp_user`
   * `WP_ADMIN_USER=the_boss`
   * `WP_USER=sousfifre`
   * `FTP_USER=the_boss`

2. **Sensitive Passwords (`secrets/` directory at the root of the project)**:
   Each password is stored in its own plain-text file (without trailing spaces or extra lines):
   * `secrets/root_db_password.txt` — MariaDB `root` password.
   * `secrets/db_password.txt` — MariaDB `wp_user` password.
   * `secrets/root_wp_password.txt` — WordPress administrator (`the_boss`) password.
   * `secrets/wp_password.txt` — WordPress author (`sousfifre`) password.
   * `secrets/ftp_password.txt` — FTP user password.

   *To change a password before deployment, edit the corresponding file in `secrets/` and run `make re`.*

---

## 5. Checking That Services Are Running Correctly

You can verify the health of the stack using the following commands:

* **Check container statuses**:
  ```bash
  docker compose -f srcs/docker-compose.yml ps
  ```
  All 8 containers (`nginx`, `wordpress`, `mariadb`, `redis`, `ftp`, `static_site`, `adminer`, `uptime_kuma`) should show the status `Up`.

* **Inspect service logs in real time**:
  ```bash
  docker compose -f srcs/docker-compose.yml logs -f
  ```
  Or for a specific service (e.g., WordPress):
  ```bash
  docker logs wordpress
  ```

* **Verify TLSv1.2 / TLSv1.3 and HTTPS response**:
  ```bash
  curl -Ik https://gematura.42.fr
  ```

* **Verify Redis Cache status in WordPress**:
  ```bash
  docker exec wordpress wp redis status --allow-root --path=/var/www/html
  ```