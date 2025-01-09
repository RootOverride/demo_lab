#!/bin/bash

START_TIME=$(date '+%Y-%m-%d %H:%M:%S')
echo ""
echo "########## ⏰ Inicio del script: $START_TIME"
echo ""
echo "########## Comprobando conexión a internet"
echo ""
ping -c4 www.google.com
ping -c4 8.8.8.8

# Actualizar los paquetes del sistema
echo ""
echo "########## Actualizando Sistema"
echo ""
sudo apt-get update -y -o Acquire::ForceIPv4=true
#sudo apt-get upgrade -y -o Acquire::ForceIPv4=true

echo ""
echo "########## Instalando Apache, MySql y PHP"
echo ""
# Instalar Apache, MySQL y PHP
sudo apt-get install -y mysql-server php libapache2-mod-php php-mysql -o Acquire::ForceIPv4=true
sudo apt-get install -y apache2 -o Acquire::ForceIPv4=true
sudo systemctl enable apache2
sudo systemctl start apache2

echo ""
echo "########## Instalando DVWA"
echo ""
# Descargar DVWA
cd /var/www/html
sudo git clone https://github.com/digininja/DVWA.git
sudo mv DVWA/ dvwa

echo ""
echo "########## Configurando Permisos"
echo ""
sudo chown -R www-data:www-data /var/www/html/dvwa/
sudo chmod -R 755 /var/www/html/dvwa/

# Configurar base de datos MySQL
echo ""
echo "########## Configurando MySql"
echo ""
sudo mysql -e "CREATE DATABASE dvwa;"
sudo mysql -e "CREATE USER 'dvwa'@'localhost' IDENTIFIED BY 'p@ssw0rd';"
sudo mysql -e "GRANT ALL PRIVILEGES ON dvwa.* TO 'dvwa'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# Configurar archivo de configuración de DVWA
echo ""
echo "########## Configurando DVWA"
echo ""
sudo cp /var/www/html/dvwa/config/config.inc.php.dist /var/www/html/dvwa/config/config.inc.php

cd /opt
sudo git clone https://github.com/RootOverride/demo_lab.git
cd demo_lab

sudo cp /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini.bak
sudo rm -Rf /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini
sudo cp ./php.ini /etc/php/$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')/apache2/php.ini

# Reiniciar Apache
echo ""
echo "########## Reiniciando Apache"
echo ""
sudo systemctl restart apache2

echo ""
echo "########## Cambiando Hostname"
echo ""
# Cambiar Hostname
sudo hostnamectl set-hostname Objetivo

START_TIMEF=$(date '+%Y-%m-%d %H:%M:%S')
echo ""
echo "########## ⏰ Finalización del script: $START_TIMEF"
echo ""
