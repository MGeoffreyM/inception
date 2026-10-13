FROM debian:bookworm-slim

RUN apt-get update -y && apt-get install -y curl git ca-certificates gnupg

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/louislam/uptime-kuma.git /app
WORKDIR /app
RUN npm run setup

EXPOSE 3001

CMD ["node", "server/server.js"]