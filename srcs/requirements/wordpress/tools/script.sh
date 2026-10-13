#!/bin/bash

cd /var/www/html

# Si wp-config.php n'existe pas, cela veut dire que c'est le premier lancement
if [ ! -f wp-config.php ]; then

    if [ ! -f "/run/secrets/db_password" ]; then
    echo "Erreur : Le fichier secret db_password est introuvable."
    exit 1
    fi

    SQL_PASSWORD=$(cat /run/secrets/db_password)

    if [ ! -f "/run/secrets/root_wp_password" ]; then
        echo "Erreur : Le fichier secret root_db_password est introuvable."
        exit 1
    fi

    WP_ADMIN_PASSWORD=$(cat /run/secrets/root_wp_password)

    if [ ! -f "/run/secrets/wp_password" ]; then
        echo "Erreur : Le fichier secret root_db_password est introuvable."
        exit 1
    fi

    WP_USER_PASSWORD=$(cat /run/secrets/wp_password)

    while ! mariadb -h mariadb -u ${SQL_USER} -p${SQL_PASSWORD} -e "SELECT 1;" >/dev/null 2>&1; do
        sleep 1
    done
    
    # 1. Création du fichier wp-config.php avec les identifiants de la base de données
    wp config create --allow-root \
        --dbname=${SQL_DATABASE} \
        --dbuser=${SQL_USER} \
        --dbpass=${SQL_PASSWORD} \
        --dbhost=mariadb \
        --skip-check

    # 2. Installation de base de WordPress (Création de l'administrateur)
    # RAPPEL DU SUJET : Le nom de cet admin ne doit pas contenir "admin" ou "administrator"
    wp core install --allow-root \
        --url=https://${DOMAIN_NAME} \
        --title="Mon Super Site Inception" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL}

    wp config set WP_REDIS_HOST redis --allow-root

    wp config set WP_REDIS_PORT 6379 --raw --allow-root

    # 3. Création du deuxième utilisateur exigé par le sujet
    wp user create --allow-root ${WP_USER} ${WP_USER_EMAIL} --user_pass=${WP_USER_PASSWORD} --role=author
    
    wp plugin install redis-cache --activate --allow-root

    wp redis enable --allow-root

    # Fixer les permissions une dernière fois (au cas où WP-CLI a créé des fichiers en root)
    chown -R www-data:www-data /var/www/html
else
    echo "WordPress est déjà configuré."
fi

# Lancement de PHP-FPM au premier plan (-F) pour garder le conteneur en vie (PID 1)
# Cette commande trouve l'exécutable PHP-FPM quelle que soit sa version (php-fpm8.2, etc.)
echo "Lancement de PHP-FPM..."
exec $(find /usr/sbin -name "php-fpm*") -F
