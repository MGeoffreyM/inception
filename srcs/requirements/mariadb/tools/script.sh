#!/bin/bash

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
# On vérifie si la base de données existe déjà. 
# Si elle existe, on ne refait pas la configuration initiale.
if [ ! -d "/var/lib/mysql/${SQL_DATABASE}" ]; then

    echo "Initialisation de la base de données..."
    service mariadb start
    
    # On attend que MariaDB est bien lancé
    echo "Attente du démarrage de MariaDB..."
    while ! mysqladmin ping --silent; do
        sleep 1
    done

    # Création de la DB et de l'utilisateur pour WordPress
    mysql -e "CREATE DATABASE IF NOT EXISTS \`${SQL_DATABASE}\`;"
    
    # On utilise '@%' pour que le conteneur WordPress puisse s'y connecter
    mysql -e "CREATE USER IF NOT EXISTS \`${SQL_USER}\`@'%' IDENTIFIED BY '${SQL_PASSWORD}';"
    mysql -e "GRANT ALL PRIVILEGES ON \`${SQL_DATABASE}\`.* TO \`${SQL_USER}\`@'%';"
    
    # Sécurisation du compte root
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${SQL_ROOT_PASSWORD}';"
    mysql -e "FLUSH PRIVILEGES;"

    # On éteint proprement le service avant de le lancer en premier plan
    mysqladmin -u root -p${SQL_ROOT_PASSWORD} shutdown

else
    echo "La base de données existe déjà. Lancement de MariaDB..."
fi

# On lance le démon en premier plan (foreground) pour que le conteneur tourne
exec mariadbd --user=mysql
