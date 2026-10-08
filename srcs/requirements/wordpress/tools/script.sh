#!/bin/bash

cd /var/www/html

# Si wp-config.php n'existe pas, cela veut dire que c'est le premier lancement
if [ ! -f wp-config.php ]; then
    echo "Configuration de WordPress en cours..."
    
    echo "En attente que MariaDB soit prêt..."
    while ! mariadb -h mariadb -u ${SQL_USER} -p${SQL_PASSWORD} -e "SELECT 1;" >/dev/null 2>&1; do
        sleep 1
    done
    echo "MariaDB est connecté et prêt !"

    # 1. Création du fichier wp-config.php avec les identifiants de la base de données
    wp config create --allow-root \
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${SQL_PASSWORD} \
        --dbhost=mariadb:3306 # 'mariadb' correspondra au nom du conteneur sur le réseau Docker

    # 2. Installation de base de WordPress (Création de l'administrateur)
    # RAPPEL DU SUJET : Le nom de cet admin ne doit pas contenir "admin" ou "administrator"
    wp core install --allow-root \
        --url=https://${DOMAIN_NAME} \
        --title="Mon Super Site Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL}

    # 3. Création du deuxième utilisateur exigé par le sujet
    wp user create --allow-root ${WP_USER} ${WP_USER_EMAIL} --user_pass=${WP_USER_PASSWORD} --role=author
    
    # Fixer les permissions une dernière fois (au cas où WP-CLI a créé des fichiers en root)
    chown -R www-data:www-data /var/www/html
else
    echo "WordPress est déjà configuré."
fi

# Lancement de PHP-FPM au premier plan (-F) pour garder le conteneur en vie (PID 1)
# Cette commande trouve l'exécutable PHP-FPM quelle que soit sa version (php-fpm8.2, etc.)
echo "Lancement de PHP-FPM..."
exec $(find /usr/sbin -name "php-fpm*") -F
