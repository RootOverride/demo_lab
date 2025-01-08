#!/bin/bash

# Actualizar los paquetes del sistema
echo "Actualizando paquetes del sistema..."
sudo apt update && sudo apt upgrade -y

# Instalar Apache, MySQL y PHP
echo "Instalando Apache, MySQL y PHP..."
sudo apt install -y apache2 php mysql-server php-mysqli git

# Descargar DVWA
echo "Descargando DVWA..."
sudo git clone https://github.com/digininja/DVWA.git /var/www/html/dvwa

# Configurar permisos
echo "Configurando permisos..."
sudo chown -R www-data:www-data /var/www/html/dvwa/
sudo chmod -R 755 /var/www/html/dvwa/

# Configurar base de datos MySQL
echo "Configurando la base de datos MySQL..."
sudo mysql -e "CREATE DATABASE dvwa;"
sudo mysql -e "CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';"
sudo mysql -e "GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Configurar archivo de configuración de DVWA
echo "Configurando archivo de DVWA..."
sudo cp /var/www/html/dvwa/config/config.inc.php.dist /var/www/html/dvwa/config/config.inc.php

sudo cp /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini.bak
sudo rm -Rf /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini
cp ./php.ini /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini

# Reiniciar Apache
echo "Reiniciando Apache..."
sudo systemctl restart apache2

# Cambiar Hostname
sudo hostnamectl set-hostname Objetivo
