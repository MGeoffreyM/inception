#!/bin/bash

if ! id -u $FTP_USER > /dev/null 2>&1; then
    useradd -m -s /bin/bash -u 33 -o $FTP_USER
    echo "$FTP_USER:$FTP_PASSWORD" | chpasswd
    usermod -d /var/www/html $FTP_USER
    
    chown -R 33:33 /var/www/html
fi

exec vsftpd /etc/vsftpd.conf