*This project has been created as part of the 42 curriculum by gematura.*

# Inception

## Description

**Inception** is a system administration and containerization project from the 42 curriculum. Its objective is to set up a complete, secure, and multi-service web infrastructure inside a Virtual Machine using **Docker** and **Docker Compose**.

Instead of relying on pre-built images from DockerHub, every service in this stack is built from scratch using custom `Dockerfile` configurations based on `debian:bookworm-slim`. Each container runs a single daemon process as `PID 1`, communicates through an isolated bridge network, and persists critical data on the host machine using Docker named volumes and Docker secrets.

---

## Project Description

### Infrastructure Overview & Design Choices

The project is structured inside the `srcs/` directory and orchestrated via `srcs/docker-compose.yml` and a root `Makefile`.

#### Mandatory Services
* **NGINX (`nginx`)**: Acts as the single entry point to the infrastructure on port `443` only, enforcing `TLSv1.2` and `TLSv1.3` encryption with a self-signed OpenSSL certificate. It forwards PHP requests to WordPress via FastCGI (`wordpress:9000`) and acts as a reverse proxy for the bonus web services.
* **WordPress + PHP-FPM (`wordpress`)**: Runs WordPress served by PHP-FPM on port `9000`. Its initialization script (`script.sh`) uses `wp-cli` to automatically configure `wp-config.php`, install WordPress, create the administrator account (`the_boss`) and a second regular user (`sousfifre`), and enable Redis caching.
* **MariaDB (`mariadb`)**: Relational database server listening on port `3306` within the internal network. It initializes the WordPress database and user privileges on first launch using credentials mounted via Docker secrets.

#### Bonus Services
* **Redis Cache (`redis`)**: In-memory data store listening on port `6379` (`maxmemory 256mb`, `allkeys-lru` policy) connected to WordPress to cache database queries and speed up page loads.
* **FTP Server (`ftp`)**: Runs `vsftpd` on port `21` (with passive ports `21100-21110`), allowing remote file management directly inside the WordPress volume (`/var/www/html`) under `UID/GID 33` (`www-data`).
* **Static Website (`static_site`)**: A lightweight Node.js HTTP server listening on internal port `3000`, serving a static HTML/CSS resume page via NGINX reverse proxy at `https://gematura.42.fr/cv/`.
* **Adminer (`adminer`)**: Database management web interface running on internal port `8080` and exposed safely through NGINX at `https://gematura.42.fr/adminer/`.
* **Uptime Kuma (`uptime_kuma`)**: Self-hosted monitoring tool (release `1.23.16`) running on internal port `3001` and served via a dedicated NGINX virtual host with WebSocket support at `https://kuma.gematura.42.fr`.

### Technical Comparisons

#### 1. Virtual Machines vs Docker
* **Virtual Machines (VMs)** virtualize an entire hardware stack (CPU, memory, disk, network) on top of a hypervisor. Each VM runs its own full guest operating system and kernel, which consumes significant RAM, disk space, and boot time, but provides complete hardware-level isolation.
* **Docker Containers** virtualize at the operating system level by sharing the host machine's Linux kernel. They use kernel namespaces (to isolate processes, network, and mounts) and control groups (`cgroups` to manage resource usage). As a result, containers are lightweight, start in milliseconds, and package only the application and its dependencies.

#### 2. Secrets vs Environment Variables
* **Environment Variables (`.env`)** are ideal for non-sensitive configuration parameters (such as domain names, database names, or usernames). However, they are visible in plain text via `docker inspect` or process environment dumps (`/proc/1/environ`), making them unsafe for sensitive credentials.
* **Docker Secrets** store sensitive data (such as database, WordPress, and FTP passwords) in dedicated files mounted in-memory (`tmpfs`) inside the container at `/run/secrets/<secret_name>`. They are never baked into image layers, do not appear in `docker inspect`, and are only accessible to containers explicitly granted access in `docker-compose.yml`.

#### 3. Docker Network vs Host Network
* **Host Network (`network: host`)** removes network isolation between the container and the Docker host: the container shares the host's IP address and port space directly. This exposes internal services (like MariaDB or Redis) to the host network and can cause port conflicts. Furthermore, it is strictly forbidden by the subject.
* **Docker Bridge Network (`driver: bridge`)** creates an isolated virtual network (`inception`) where containers can communicate with each other using their service names via Docker's embedded DNS server (e.g., `wordpress` connects to `mariadb:3306` and `redis:6379`), while only explicitly published ports (`443` and `21`) are reachable from the outside.

#### 4. Docker Volumes vs Bind Mounts
* **Bind Mounts** directly mount a specific file or directory path from the host filesystem into a container. They rely heavily on the host's directory structure and are not managed through Docker's volume lifecycle commands (`docker volume ls`, `docker volume inspect`). Direct bind mounts are prohibited by the subject.
* **Docker Named Volumes** are storage entities managed by Docker. In this project, we define named volumes (`mariadb_data`, `wordpress_data`, `uptime_kuma_data`) using the `local` driver with `driver_opts` (`o: bind`) so that Docker manages them as named volumes while storing the underlying persistent data inside `/home/gematura/data/` on the host machine, as required by the subject.

---

## Instructions

### Prerequisites
1. A Linux Virtual Machine with **Docker Engine**, **Docker Compose**, **Make**, and **Git** installed.
2. Map the project domains to your local IP in `/etc/hosts`:
   ```bash
   127.0.0.1 gematura.42.fr kuma.gematura.42.fr
   ```
3. Create the `srcs/.env` file and the `secrets/` directory containing the required password files (`db_password.txt`, `root_db_password.txt`, `wp_password.txt`, `root_wp_password.txt`, `ftp_password.txt`). *(See `DEV_DOC.md` for detailed setup instructions).*

### Compilation & Execution
Use the root `Makefile` to build and manage the infrastructure:
* **Build and start all services**:
  ```bash
  make
  ```
* **Stop running containers**:
  ```bash
  make down
  ```
* **Remove containers, images, volumes, and host data**:
  ```bash
  make clean
  ```
* **Full Docker system prune and reset**:
  ```bash
  make fclean
  ```
* **Rebuild everything from scratch**:
  ```bash
  make re
  ```

---

## Resources

### Classic References
* [Official Docker Documentation](https://docs.docker.com/) — Dockerfile reference, multi-container networking, volumes, and secrets.
* [Docker Compose Specification](https://docs.docker.com/compose/compose-file/) — Service definitions, `depends_on`, and volume driver options.
* [NGINX Documentation](https://nginx.org/en/docs/) — HTTPS/TLS configuration, FastCGI proxying, and WebSocket reverse proxying.
* [WP-CLI Commands Reference](https://developer.wordpress.org/cli/commands/) — Automated headless WordPress installation and Redis plugin setup.
* [MariaDB Knowledge Base](https://mariadb.com/kb/en/) — Daemon configuration and SQL user privilege initialization.
* [Uptime Kuma Wiki](https://github.com/louislam/uptime-kuma/wiki) — Installation from source and reverse proxy configuration.

### Use of Artificial Intelligence
In accordance with the 42 AI guidelines, AI tools were used as a learning and review assistant for the following tasks:
* **Project Audit & Subject Compliance**: Reviewing `Dockerfile` scripts, `docker-compose.yml`, and `nginx.conf` against the subject requirements to detect configuration edge cases (such as `try_files` handling in NGINX and volume paths for Uptime Kuma).
* **Service Synchronization**: Designing the readiness check loop (`redis-cli ping`) in the WordPress entrypoint script to ensure Redis is ready before enabling object caching.
* **Documentation Structuring**: Assisting in structuring and translating the project documentation (`README.md`, `USER_DOC.md`, and `DEV_DOC.md`) to ensure clarity and completeness.