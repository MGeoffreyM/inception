FROM debian:bookworm-slim

RUN apt-get update -y && apt-get upgrade -y && apt-get install -y redis-server \
    && rm -rf /var/lib/apt/lists/*

COPY conf/redis.conf /etc/redis.conf

CMD ["redis-server", "/etc/redis.conf"]
