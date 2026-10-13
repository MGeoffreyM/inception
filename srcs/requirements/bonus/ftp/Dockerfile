FROM debian:bookworm-slim

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y vsftpd \
    && rm -rf /var/lib/apt/lists/*

COPY conf/vsftpd.conf /etc/vsftpd.conf
COPY tools/script.sh /script.sh

RUN chmod +x /script.sh

ENTRYPOINT ["/script.sh"]
