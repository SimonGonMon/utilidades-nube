#!/bin/bash

# WordPress Installation Script - FAST VERSION
# Compatible with AWS EC2 instances
# Author: DonG Script - Fast Edition
# Version: 1.1 (Optimized)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ASCII Art Function
show_ascii_art() {
    clear
    echo -e "${PURPLE}"
    echo "██████╗  ██████╗ ███╗   ██╗ ██████╗ "
    echo "██╔══██╗██╔═══██╗████╗  ██║██╔════╝ "
    echo "██║  ██║██║   ██║██╔██╗ ██║██║  ███╗"
    echo "██║  ██║██║   ██║██║╚██╗██║██║   ██║"
    echo "██████╔╝╚██████╔╝██║ ╚████║╚██████╔╝"
    echo "╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ "
    echo -e "${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}        WordPress Installation Script v1.1 (FAST)         ${NC}"
    echo -e "${WHITE}          Ubuntu + Apache2 + MySQL + WordPress            ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    sleep 1
}

# Function to print step headers
print_step() {
    echo ""
    echo -e "${BLUE}┌─────────────────────────────────────────────────────────┐${NC}"
    echo -e "${BLUE}│ ${WHITE}$1${BLUE}$(printf "%*s" $((55 - ${#1})) "")│${NC}"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print info messages
print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

# Function to print error messages
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to show progress
show_progress() {
    local pid=$1
    local message="$2"
    echo -n -e "${YELLOW}$message"
    while kill -0 $pid 2>/dev/null; do
        echo -n "."
        sleep 0.5
    done
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Este script debe ejecutarse como root (usa sudo)"
        exit 1
    fi
}

# Database configuration
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="WpSecure2024!"
DB_ROOT_PASS="RootSecure2024!"

# WordPress configuration
WP_URL="https://wordpress.org/latest.tar.gz"
WP_DIR="/var/www/html/wordpress"

# Show ASCII art
show_ascii_art

# Check root privileges
check_root

# Step 1: Update system (FAST VERSION)
print_step "PASO 1: Actualizando repositorios"
print_info "Actualizando lista de paquetes..."
apt update -qq > /dev/null 2>&1
print_success "Repositorios actualizados"

print_info "Omitiendo actualización completa del sistema para mayor velocidad..."
print_success "Se instalará solo lo necesario para WordPress"

# Step 2: Install dependencies
print_step "PASO 2: Instalando dependencias básicas"

print_info "Instalando Apache2..."
(apt install -y apache2 > /dev/null 2>&1) &
show_progress $! "Instalando Apache2"
print_success "Apache2 instalado"

print_info "Configurando MySQL Server..."
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
(apt install -y mysql-server > /dev/null 2>&1) &
show_progress $! "Instalando MySQL"
print_success "MySQL Server instalado"

print_info "Instalando PHP y extensiones necesarias..."
(apt install -y php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl > /dev/null 2>&1) &
show_progress $! "Instalando PHP"
print_success "PHP y extensiones instaladas"

print_info "Instalando herramientas básicas..."
apt install -y wget curl unzip > /dev/null 2>&1
print_success "Herramientas instaladas"

# Step 3: Configure services
print_step "PASO 3: Configurando servicios"
print_info "Iniciando Apache2..."
systemctl start apache2
systemctl enable apache2 > /dev/null 2>&1
print_success "Apache2 ejecutándose"

print_info "Iniciando MySQL..."
systemctl start mysql
systemctl enable mysql > /dev/null 2>&1
print_success "MySQL ejecutándose"

print_info "Habilitando módulo rewrite..."
a2enmod rewrite > /dev/null 2>&1
print_success "Módulo rewrite habilitado"

# Step 4: Configure MySQL
print_step "PASO 4: Configurando base de datos"
print_info "Creando base de datos WordPress..."

mysql -u root -p$DB_ROOT_PASS <<EOF > /dev/null 2>&1
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

print_success "Base de datos '$DB_NAME' creada"
print_success "Usuario '$DB_USER' configurado"

# Step 5: Download WordPress
print_step "PASO 5: Descargando WordPress"
print_info "Descargando desde wordpress.org..."
cd /tmp
(wget -q $WP_URL -O wordpress.tar.gz) &
show_progress $! "Descargando WordPress"
print_success "WordPress descargado"

print_info "Extrayendo archivos..."
tar -xzf wordpress.tar.gz > /dev/null 2>&1
print_success "Archivos extraídos"

# Step 6: Install WordPress
print_step "PASO 6: Instalando WordPress"
print_info "Copiando archivos..."
cp -R wordpress $WP_DIR
print_success "Archivos copiados a $WP_DIR"

print_info "Configurando permisos..."
chown -R www-data:www-data $WP_DIR
chmod -R 755 $WP_DIR
print_success "Permisos configurados"

print_info "Creando configuración..."
cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php

# Configure wp-config.php
sed -i "s/database_name_here/$DB_NAME/" $WP_DIR/wp-config.php
sed -i "s/username_here/$DB_USER/" $WP_DIR/wp-config.php
sed -i "s/password_here/$DB_PASS/" $WP_DIR/wp-config.php

# Add security keys
print_info "Generando claves de seguridad..."
(SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s $WP_DIR/wp-config.php > /dev/null 2>&1) &
show_progress $! "Configurando seguridad"

print_success "WordPress configurado"

# Step 7: Configure Apache Virtual Host
print_step "PASO 7: Configurando Apache"
print_info "Creando Virtual Host..."

cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    ServerName localhost
    DocumentRoot $WP_DIR
    
    <Directory $WP_DIR>
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/wordpress_error.log
    CustomLog \${APACHE_LOG_DIR}/wordpress_access.log combined
</VirtualHost>
EOF

a2ensite wordpress.conf > /dev/null 2>&1
a2dissite 000-default > /dev/null 2>&1
systemctl reload apache2
print_success "Apache configurado y reiniciado"

# Step 8: Cleanup
print_step "PASO 8: Limpieza"
rm -rf /tmp/wordpress*
print_success "Archivos temporales eliminados"

# Final message
print_step "¡INSTALACIÓN COMPLETADA!"
echo ""
echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                    ¡ÉXITO TOTAL!                       │${NC}"
echo -e "${GREEN}│         WordPress listo en tiempo récord               │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                   ACCESO A WORDPRESS                     ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Get public IP
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || curl -s http://ipinfo.io/ip 2>/dev/null || hostname -I | awk '{print $1}')

echo -e "${YELLOW}🌐 URL Principal:${NC}        http://$PUBLIC_IP/wordpress"
echo -e "${YELLOW}🌐 URL Local:${NC}            http://localhost/wordpress"
echo -e "${YELLOW}📁 Directorio:${NC}           $WP_DIR"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                  CREDENCIALES DE BD                      ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🗄️  Base de datos:${NC}       $DB_NAME"
echo -e "${YELLOW}👤 Usuario:${NC}              $DB_USER"
echo -e "${YELLOW}🔑 Contraseña:${NC}           $DB_PASS"
echo -e "${YELLOW}🔐 Root MySQL:${NC}           $DB_ROOT_PASS"
echo ""

# Check services
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                    ESTADO SERVICIOS                      ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

systemctl is-active --quiet apache2 && echo -e "${GREEN}  ✓ Apache2: Ejecutándose correctamente${NC}" || echo -e "${RED}  ✗ Apache2: Error${NC}"
systemctl is-active --quiet mysql && echo -e "${GREEN}  ✓ MySQL: Ejecutándose correctamente${NC}" || echo -e "${RED}  ✗ MySQL: Error${NC}"

echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                 NEXT STEPS - PRÓXIMOS PASOS              ${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}1.${NC} Abre: ${CYAN}http://$PUBLIC_IP/wordpress${NC}"
echo -e "${GREEN}2.${NC} Selecciona tu idioma"
echo -e "${GREEN}3.${NC} Crea tu usuario admin"
echo -e "${GREEN}4.${NC} ¡Listo para usar!"
echo ""
echo -e "${YELLOW}💡 Tip: Si usas AWS, asegúrate de tener el puerto 80 abierto${NC}"
echo ""
echo -e "${CYAN}Instalación completada en: $(date)${NC}"
echo -e "${PURPLE}Script by DonG - Versión Fast${NC}"
echo ""
