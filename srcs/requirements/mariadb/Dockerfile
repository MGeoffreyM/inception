FROM debian:bookworm-slim

RUN apt update -y && apt upgrade -y && apt install mariadb-server -y \
    && rm -rf /var/lib/apt/lists/*

COPY conf/50-server.cnf	/etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/script.sh /script.sh

RUN chmod +x /script.sh

ENTRYPOINT ["/script.sh"]
