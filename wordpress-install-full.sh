#!/bin/bash

# WordPress Installation Script for Ubuntu + Apache2 + MySQL
# Compatible with AWS EC2 instances
# Author: DonG Script
# Version: 1.0

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
    echo -e "${WHITE}          WordPress Installation Script v1.0              ${NC}"
    echo -e "${WHITE}          Ubuntu + Apache2 + MySQL + WordPress            ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    sleep 2
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

# Step 1: Update system
print_step "PASO 1: Actualizando el sistema"
print_info "Actualizando repositorios..."
apt update -qq > /dev/null 2>&1
print_success "Repositorios actualizados"

print_info "Actualizando paquetes del sistema..."
apt upgrade -y -qq > /dev/null 2>&1
print_success "Sistema actualizado correctamente"

# Step 2: Install dependencies
print_step "PASO 2: Instalando dependencias básicas"
print_info "Instalando Apache2..."
apt install -y apache2 > /dev/null 2>&1
print_success "Apache2 instalado"

print_info "Instalando MySQL Server..."
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DB_ROOT_PASS"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DB_ROOT_PASS"
apt install -y mysql-server > /dev/null 2>&1
print_success "MySQL Server instalado"

print_info "Instalando PHP y extensiones..."
apt install -y php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php-intl > /dev/null 2>&1
print_success "PHP y extensiones instaladas"

print_info "Instalando herramientas adicionales..."
apt install -y wget curl unzip > /dev/null 2>&1
print_success "Herramientas adicionales instaladas"

# Step 3: Configure services
print_step "PASO 3: Configurando servicios"
print_info "Iniciando y habilitando Apache2..."
systemctl start apache2
systemctl enable apache2 > /dev/null 2>&1
print_success "Apache2 configurado y ejecutándose"

print_info "Iniciando y habilitando MySQL..."
systemctl start mysql
systemctl enable mysql > /dev/null 2>&1
print_success "MySQL configurado y ejecutándose"

print_info "Habilitando módulos de Apache..."
a2enmod rewrite > /dev/null 2>&1
print_success "Módulo rewrite habilitado"

# Step 4: Configure MySQL
print_step "PASO 4: Configurando base de datos MySQL"
print_info "Creando base de datos y usuario para WordPress..."

mysql -u root -p$DB_ROOT_PASS <<EOF > /dev/null 2>&1
CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EXIT;
EOF

print_success "Base de datos '$DB_NAME' creada"
print_success "Usuario '$DB_USER' creado con permisos completos"

# Step 5: Download and extract WordPress
print_step "PASO 5: Descargando WordPress"
print_info "Descargando WordPress desde wordpress.org..."
cd /tmp
wget -q $WP_URL -O wordpress.tar.gz
print_success "WordPress descargado exitosamente"

print_info "Extrayendo archivos de WordPress..."
tar -xzf wordpress.tar.gz > /dev/null 2>&1
print_success "Archivos extraídos correctamente"

# Step 6: Install WordPress
print_step "PASO 6: Instalando WordPress"
print_info "Moviendo archivos a /var/www/html/..."
cp -R wordpress $WP_DIR
print_success "Archivos de WordPress copiados"

print_info "Configurando permisos..."
chown -R www-data:www-data $WP_DIR
chmod -R 755 $WP_DIR
print_success "Permisos configurados correctamente"

print_info "Creando archivo de configuración..."
cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php

# Configure wp-config.php
sed -i "s/database_name_here/$DB_NAME/" $WP_DIR/wp-config.php
sed -i "s/username_here/$DB_USER/" $WP_DIR/wp-config.php
sed -i "s/password_here/$DB_PASS/" $WP_DIR/wp-config.php

# Add security keys
print_info "Generando claves de seguridad..."
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s $WP_DIR/wp-config.php > /dev/null 2>&1

print_success "Configuración de WordPress completada"

# Step 7: Configure Apache Virtual Host
print_step "PASO 7: Configurando Virtual Host de Apache"
print_info "Creando configuración de Virtual Host..."

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

print_success "Virtual Host creado"

print_info "Habilitando sitio de WordPress..."
a2ensite wordpress.conf > /dev/null 2>&1
print_success "Sitio habilitado"

print_info "Deshabilitando sitio por defecto..."
a2dissite 000-default > /dev/null 2>&1
print_success "Sitio por defecto deshabilitado"

print_info "Reiniciando Apache..."
systemctl reload apache2
print_success "Apache reiniciado correctamente"

# Step 8: Configure firewall (if ufw is available)
print_step "PASO 8: Configurando firewall"
if command -v ufw &> /dev/null; then
    print_info "Configurando reglas de firewall..."
    ufw --force enable > /dev/null 2>&1
    ufw allow ssh > /dev/null 2>&1
    ufw allow 'Apache Full' > /dev/null 2>&1
    print_success "Firewall configurado (SSH y HTTP/HTTPS permitidos)"
else
    print_info "UFW no está instalado, omitiendo configuración de firewall"
fi

# Step 9: Cleanup
print_step "PASO 9: Limpieza final"
print_info "Eliminando archivos temporales..."
rm -rf /tmp/wordpress*
print_success "Archivos temporales eliminados"

# Final message
print_step "INSTALACIÓN COMPLETADA"
echo ""
echo -e "${GREEN}┌─────────────────────────────────────────────────────────┐${NC}"
echo -e "${GREEN}│                    ¡ÉXITO TOTAL!                       │${NC}"
echo -e "${GREEN}│         WordPress instalado correctamente              │${NC}"
echo -e "${GREEN}└─────────────────────────────────────────────────────────┘${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                   INFORMACIÓN DEL SISTEMA                ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🌐 URL de WordPress:${NC}     http://$(curl -s http://checkip.amazonaws.com || hostname -I | awk '{print $1}')/wordpress"
echo -e "${YELLOW}📁 Directorio:${NC}           $WP_DIR"
echo -e "${YELLOW}🗄️  Base de datos:${NC}       $DB_NAME"
echo -e "${YELLOW}👤 Usuario DB:${NC}           $DB_USER"
echo -e "${YELLOW}🔑 Contraseña DB:${NC}        $DB_PASS"
echo -e "${YELLOW}🔐 Root MySQL:${NC}           $DB_ROOT_PASS"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                      PRÓXIMOS PASOS                      ${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}1.${NC} Abre tu navegador y visita la URL mostrada arriba"
echo -e "${GREEN}2.${NC} Completa la instalación de WordPress desde el navegador"
echo -e "${GREEN}3.${NC} Crea tu usuario administrador"
echo -e "${GREEN}4.${NC} ¡Disfruta de tu nuevo sitio WordPress!"
echo ""
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}                  Instalación por DonG                    ${NC}"
echo -e "${PURPLE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Show services status
print_info "Estado de los servicios:"
systemctl is-active --quiet apache2 && echo -e "${GREEN}  ✓ Apache2: Ejecutándose${NC}" || echo -e "${RED}  ✗ Apache2: Detenido${NC}"
systemctl is-active --quiet mysql && echo -e "${GREEN}  ✓ MySQL: Ejecutándose${NC}" || echo -e "${RED}  ✗ MySQL: Detenido${NC}"

echo ""
echo -e "${CYAN}Instalación completada en: $(date)${NC}"
echo ""
