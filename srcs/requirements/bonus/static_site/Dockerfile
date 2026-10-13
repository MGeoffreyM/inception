FROM debian:bookworm-slim

RUN apt-get update -y && apt-get install -y nodejs && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/static

COPY conf/index.html /var/www/static/index.html

COPY conf/image1.jpg /var/www/static/image1.jpg
COPY conf/image2.jpg /var/www/static/image2.jpg

COPY conf/server.js /server.js

EXPOSE 3000

ENTRYPOINT ["node", "/server.js"]
