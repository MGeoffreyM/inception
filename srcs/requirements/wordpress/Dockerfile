FROM debian:trixie-slim

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y wget php-fpm php-mysql mariadb-client tar ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

RUN mkdir -p /var/www/html

RUN wget https://fr.wordpress.org/wordpress-7.1.2-fr_FR.tar.gz -P /tmp && \
    tar -xzf /tmp/wordpress-7.1.2-fr_FR.tar.gz -C /var/www/html --strip-components=1 && \
    rm /tmp/wordpress-7.1.2-fr_FR.tar.gz

RUN chown -R www-data:www-data /var/www/html
RUN mkdir -p /run/php

RUN sed -i 's/listen = \/run\/php\/php.*-fpm.sock/listen = 9000/g' /etc/php/*/fpm/pool.d/www.conf

COPY tools/script.sh /script.sh
RUN chmod +x /script.sh

ENTRYPOINT ["/script.sh"]
