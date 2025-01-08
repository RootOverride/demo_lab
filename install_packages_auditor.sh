#!/bin/bash
# Actualización del sistema operativo
sudo apt update -y
sudo apt upgrade -y

# Instacion Librerias Python3
sudo apt install python3-pip -y
sudo pip install virtualenv -y

# Instalación de Metasploit (Framework Pruebas de Penetración)
curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
sudo chmod 755 msfinstall
sudo ./msfinstall

# Instalación de Nmap (Enumeración)
sudo apt install nmap -y

# Instalación de HPing3 (Enviar paquetes ICMP/UDP/TCP personalizados)
sudo apt install hping3 -y

# Instalación de Scapy (Manipulación de paquetes)
sudo apt install python3-scapy -y

# Instalación de Yersinia (Ataques de Red)
sudo apt install yersinia -y

# Instalación de Wfuzz (Fuzzing)
sudo apt install wfuzz -y
sudo apt install gobuster -y

# Instalación de SQLMap (Inyecciones SQL)
sudo apt install sqlmap -y

# Instalación de Hydra (Ataques de Fuerza Bruta)
sudo apt install hydra -y

# Instalación de John the Ripper (Descifrador de contraseñas)
sudo apt install john -y

# Instalación de DNSRecon (Herramienta de escaneo y enumeración DNS)
sudo apt install dnsrecon -y

# Instalación de WhatWeb (Recopila información de sito Web)
sudo apt install whatweb -y

# Instalación de Evil-WinRM (Marco de pruebas de penetración)
sudo gem install evil-winrm

# Instalación de OpenVAS (Escáner de vulnerabilidades)
#sudo apt install -y gvm
#sudo gvm-setup
#sudo systemctl start gvmd
#sudo systemctl start ospd-openvas
#sudo systemctl start gsad

# Descargar Diccionarios
cd /home/ubuntu/
mkdir diccionarios
cd diccionarios
git clone https://github.com/danielmiessler/SecLists.git

# Cambiar Hostname
sudo hostnamectl set-hostname Hacker

# Instlación de Tshark (Captura y Analisis de Paquetes)
sudo DEBIAN_FRONTEND=noninteractive apt install tshark -y
