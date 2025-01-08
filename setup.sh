#!/bin/bash

echo ""
echo "############################################################################################################################"
echo "Configurando Laboratorio... Instituto Profesional IACC"
echo "############################################################################################################################"
echo ""

# Solicitar nombre y apellido
read -p "Ingrese su nombre y apellido juntos (ejemplo: NombreApellido): " email

# Crear VPC
vpc_id=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
if [ $? -ne 0 ]; then
  echo "❌ Error al crear la VPC. Abortando."
  exit 1
fi
echo "✅ VPC creada con ID: $vpc_id"

# Asignar nombre a la VPC
aws ec2 create-tags --resources $vpc_id --tags Key=Name,Value="$email"
echo "✅ VPC etiquetada con el nombre: $email"

# Crear Subnet
subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
echo "✅ Subnet creada con ID: $subnet_id"

# Crear Internet Gateway
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
echo "✅ Internet Gateway creada con ID: $igw_id"

# Asociar Internet Gateway a la VPC
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id
echo "✅ Internet Gateway asociada a la VPC"

# Crear Tabla de Rutas
route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id --query 'RouteTable.RouteTableId' --output text)
echo "✅ Tabla de rutas creada con ID: $route_table_id"

# Crear Ruta para permitir tráfico a Internet
aws ec2 create-route --route-table-id $route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id > /dev/null 2>&1
echo "✅ Ruta a Internet creada en la tabla de rutas"

# Asociar Tabla de Rutas a la Subnet
aws ec2 associate-route-table --route-table-id $route_table_id --subnet-id $subnet_id > /dev/null 2>&1
echo "✅ Tabla de rutas asociada a la Subnet"

# Crear Security Group
sg_id=$(aws ec2 create-security-group --group-name "$email-sg" --description "Security Group para $email" --vpc-id $vpc_id --query 'GroupId' --output text)
echo "✅ Security Group creado con ID: $sg_id"

# Permitir tráfico SSH
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 22 --cidr 0.0.0.0/0
echo "✅ Se habilita el puerto 22 (SSH)"

# Permitir tráfico Web
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol tcp --port 443 --cidr 0.0.0.0/0
echo "✅ Se habilitan puertos 80 y 443 (HTTP, HTTPS)"

# Permitir todo el tráfico interno
aws ec2 authorize-security-group-ingress --group-id $sg_id --protocol -1 --port -1 --cidr 10.0.0.0/16
echo "✅ Tráfico interno permitido"

# Crear Key Pair
#aws ec2 create-key-pair --key-name "$email" --query 'KeyMaterial' --output text > "${email}.pem"
#chmod 400 "${email}.pem"
#echo "✅ Par de llaves creadas: ${email}.pem"

# Lanzar dos instancias Ubuntu
ami_id=$(aws ec2 describe-images --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" --query 'Images[0].ImageId' --output text)

# Creando instancia Ethical Hacking
instance_id1=$(aws ec2 run-instances \
              --image-id $ami_id \
              --instance-type t2.micro \
              --key-name vockey \
              --security-group-ids $sg_id \
              --subnet-id $subnet_id \
              --user-data file://install_packages_auditor.sh \
              --query 'Instances[*].InstanceId' \
              --output text \
              --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EthicalHacking}]')

instance_id2=$(aws ec2 run-instances \
              --image-id $ami_id \
              --instance-type t2.micro \
              --key-name vockey \
              --security-group-ids $sg_id \
              --subnet-id $subnet_id \
              --query 'Instances[*].InstanceId' \
              --output text \
              --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=MaquinaObjetivo}]')
echo "✅ Instancias lanzadas con los siguientes IDs: $instance_id1 - $instance_id2"

# Obtener el primer InstanceId
echo "📌 Primera instancia seleccionada para asignar Elastic IP: $instance_id1"
echo "⏳ Esperando a que la instancia $instance_id1 esté disponible para asociar la IP elastica..."
sleep 100

# Crear y asociar Elastic IP
eip_allocation_id1=$(aws ec2 allocate-address --query 'AllocationId' --output text)
aws ec2 associate-address --instance-id $instance_id1 --allocation-id $eip_allocation_id1 > /dev/null 2>&1
echo "✅ Elastic IP asignada a la instancia: $instance_id1"

echo "📌 Segunda instancia seleccionada para asignar Elastic IP: $instance_id2"
echo "⏳ Esperando a que la instancia $instance_id2 esté disponible para asociar la IP elastica..."

# Crear y asociar Elastic IP
eip_allocation_id2=$(aws ec2 allocate-address --query 'AllocationId' --output text)
aws ec2 associate-address --instance-id $instance_id2 --allocation-id $eip_allocation_id2 > /dev/null 2>&1
echo "✅ Elastic IP asignada a la instancia: $instance_id2"

###### Crear Red VPN

# Crear un endpoint de Client VPN
client_vpn_endpoint_id=$(aws ec2 create-client-vpn-endpoint \
    --client-cidr-block 10.1.0.0/16 \
    --server-certificate-arn "arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID" \
    --authentication-options Type=certificate-authentication,MutualAuthentication={ClientRootCertificateChainArn="arn:aws:acm:REGION:ACCOUNT_ID:certificate/CERTIFICATE_ID"} \
    --connection-log-options Enabled=false \
    --query 'ClientVpnEndpoint.ClientVpnEndpointId' \
    --output text)

echo "✅ Client VPN Endpoint creado con ID: $client_vpn_endpoint_id"

# Asociar la VPN a la Subnet
association_id=$(aws ec2 associate-client-vpn-target-network \
    --client-vpn-endpoint-id $client_vpn_endpoint_id \
    --subnet-id $subnet_id \
    --query 'AssociationId' \
    --output text)

echo "✅ Client VPN asociado a la subnet con ID: $association_id"

# Crear tabla de rutas
aws ec2 create-client-vpn-route \
    --client-vpn-endpoint-id $client_vpn_endpoint_id \
    --destination-cidr-block 10.0.0.0/16 \
    --target-vpc-subnet-id $subnet_id

echo "✅ Ruta creada para permitir tráfico interno en la VPN"

# Configurar reglas de autorización
aws ec2 authorize-client-vpn-ingress \
    --client-vpn-endpoint-id $client_vpn_endpoint_id \
    --target-network-cidr 10.0.0.0/16 \
    --authorize-all-groups

echo "✅ Reglas de autorización configuradas para la VPN"

# Descargar archivo de configuración de la VPN
aws ec2 export-client-vpn-client-configuration \
    --client-vpn-endpoint-id $client_vpn_endpoint_id \
    --output text > client-config.ovpn

echo "✅ Archivo de configuración de VPN descargado: client-config.ovpn"


###### Instalación de paquetes en maquina 1

# Obtener la dirección IP pública de la instancia
#public_ip1=$(aws ec2 describe-instances --instance-ids $instance_id1 --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
#echo ""
#echo "📡 Conectando a la instancia en $public_ip1..."

# Esperar a que la instancia esté lista para SSH
#echo "⏳ Esperando que las instancias esté lista para conexión SSH..."
#sleep 60

#chmod 400 "${email}.pem"

# Conectar por SSH y ejecutar comandos remotos
#ssh -o StrictHostKeyChecking=no -i "${email}.pem" ubuntu@$public_ip1 << 'EOF' 
#  echo "✅ Conexión SSH establecida"
  
  # Actualizar el sistema
#  sudo apt update -y > /dev/null 2>&1
#  echo "✅ Repositorios Actualizados."
  
#  sudo apt install nmap -y

#  echo "✅ Herramientas necesarias instaladas!"
  
  # Salir
#  exit
#EOF

# Obtener la dirección IP pública de la instancia
#public_ip2=$(aws ec2 describe-instances --instance-ids $instance_id2 --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
#echo ""

#echo "📡 Conectando a la instancia en $public_ip2..."
# Conectar por SSH y ejecutar comandos remotos
#ssh -o StrictHostKeyChecking=no -i "${email}.pem" ubuntu@$public_ip2 << 'EOF'
#  echo "✅ Conexión SSH establecida a $public_ip2"

  # Actualizar el sistema
#  sudo apt update -y > /dev/null 2>&1
#  echo "✅ Repositorios Actualizados."
  

#  echo "✅ Herramientas necesarias instaladas en $public_ip2"
  
  # Salir
#  exit
#EOF


echo "✅ Comandos remotos ejecutados en la instancia en $instance_id1 y $instance_id1"



# Verificar las instancias
aws ec2 describe-instances --instance-ids $instance_id1 $instance_id2 --query "Reservations[*].Instances[*].{ID:InstanceId,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress,State:State.Name}" --output table
#cat "${email}.pem"
echo ""
cat client-config.ovpn

echo ""
echo "############################################################################################################################"
echo "✅✅✅ Proceso Finalizado: Su laboratorio ya se encuentra disponible, ahora! Es tu momento de Brillar!!!..."
echo "Ejemplo de conexión: ssh -o StrictHostKeyChecking=no -i 'NombreApellido.pem' ubuntu@ip_publica "
echo "############################################################################################################################"
echo ""