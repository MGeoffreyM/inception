#!/bin/bash

if [ ! -f "/run/secrets/ftp_password" ]; then
    echo "Erreur : Le fichier secret ftp_password est introuvable."
    exit 1
fi

FTP_PASSWORD=$(cat /run/secrets/ftp_password)

if ! id -u $FTP_USER > /dev/null 2>&1; then
    useradd -m -s /bin/bash -u 33 -o $FTP_USER
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    usermod -d /var/www/html $FTP_USER
    
    chown -R 33:33 /var/www/html
fi

mkdir -p /var/run/vsftpd/empty

exec vsftpd /etc/vsftpd.conf