#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTANCES_DIR="/wordpress-instances"

# Default values from environment variables (set in docker-compose-dind.yml from .env)
DEFAULT_SITE_TITLE="${WORDPRESS_WEBSITE_TITLE:-My WordPress Site}"
DEFAULT_ADMIN_USER="${WORDPRESS_ADMIN_USER:-admin}"
DEFAULT_ADMIN_EMAIL="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}"
DEFAULT_ADMIN_PASSWORD="${WORDPRESS_ADMIN_PASSWORD:-}"  # Empty means generate random
DEFAULT_LOCALE="${WORDPRESS_LOCALE:-en_US}"

# Function to print colored messages
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to install WordPress
install_wordpress() {
    local instance_name=$1
    local instance_dir="${INSTANCES_DIR}/${instance_name}"
    
    if [ ! -d "$instance_dir" ]; then
        print_error "Instance '${instance_name}' does not exist!"
        return 1
    fi
    
    local wordpress_dir="${instance_dir}/data/wordpress"
    
    # Check if WordPress is already installed
    if [ -f "${wordpress_dir}/wp-config.php" ]; then
        print_warning "WordPress appears to be already installed in '${instance_name}'"
        read -p "Do you want to reinstall? This will DELETE all existing data! (yes/no): " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Installation cancelled."
            return 0
        fi
        
        # Remove existing WordPress files
        print_info "Removing existing WordPress installation..."
        rm -rf "${wordpress_dir}"/*
        rm -rf "${wordpress_dir}"/.[!.]*
    fi
    
    # Create wordpress directory if it doesn't exist
    mkdir -p "${wordpress_dir}"
    
    # Get database credentials from docker-compose.yml
    local compose_file="${instance_dir}/docker-compose.yml"
    if [ ! -f "$compose_file" ]; then
        print_error "docker-compose.yml not found for instance '${instance_name}'"
        return 1
    fi
    
    # Extract database credentials
    local db_name=$(grep "MYSQL_DATABASE:" "$compose_file" | awk '{print $2}')
    local db_user=$(grep "MYSQL_USER:" "$compose_file" | awk '{print $2}')
    local db_password=$(grep "WORDPRESS_DB_PASSWORD:" "$compose_file" | head -1 | awk '{print $2}')
    local db_host="mysql:3306"
    
    print_info "Downloading latest WordPress..."
    wp core download --path="${wordpress_dir}"
    
    print_info "Creating wp-config.php..."
    wp config create \
        --path="${wordpress_dir}" \
        --dbname="${db_name}" \
        --dbuser="${db_user}" \
        --dbpass="${db_password}" \
        --dbhost="${db_host}" \
       
    
    # Add additional wp-config.php settings
    print_info "Configuring WordPress settings..."
    
    # Add debugging settings (disabled by default)
    wp config set WP_DEBUG false --raw --path="${wordpress_dir}"
    wp config set WP_DEBUG_LOG false --raw --path="${wordpress_dir}"
    wp config set WP_DEBUG_DISPLAY false --raw --path="${wordpress_dir}"
    
    # Add memory limits
    wp config set WP_MEMORY_LIMIT '256M' --path="${wordpress_dir}"
    wp config set WP_MAX_MEMORY_LIMIT '512M' --path="${wordpress_dir}"
    
    # Get site URL (find the mapped port)
    local container_name="${instance_name}-nginx"
    if ! docker ps --format '{{.Names}}' | grep -q "${instance_name}-nginx"; then
        container_name="${instance_name}-apache"
    fi
    
    local port=$(docker port "$container_name" 80 2>/dev/null | cut -d: -f2)
    local site_url="http://localhost:${port}"
    
    if [ -z "$port" ]; then
        print_warning "Could not determine site URL. Using http://localhost"
        site_url="http://localhost"
    fi
    
    # Prompt for site details (with defaults from .env)
    print_info "WordPress installation details:"
    read -p "Site Title [${DEFAULT_SITE_TITLE}]: " site_title
    site_title=${site_title:-"${DEFAULT_SITE_TITLE}"}

    read -p "Admin Username [${DEFAULT_ADMIN_USER}]: " admin_user
    admin_user=${admin_user:-"${DEFAULT_ADMIN_USER}"}

    read -p "Admin Email [${DEFAULT_ADMIN_EMAIL}]: " admin_email
    admin_email=${admin_email:-"${DEFAULT_ADMIN_EMAIL}"}

    # Use password from .env or generate random one
    if [ -n "$DEFAULT_ADMIN_PASSWORD" ] && [ "$DEFAULT_ADMIN_PASSWORD" != "change-this-password" ]; then
        admin_password="$DEFAULT_ADMIN_PASSWORD"
        print_info "Using admin password from configuration"
    else
        admin_password=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
        print_info "Generated random admin password"
    fi
    
    print_info "Installing WordPress..."
    wp core install \
        --path="${wordpress_dir}" \
        --url="${site_url}" \
        --title="${site_title}" \
        --admin_user="${admin_user}" \
        --admin_password="${admin_password}" \
        --admin_email="${admin_email}" \
        --skip-email \
       
    
    # Set proper permissions
    print_info "Setting file permissions..."
    chown -R 82:82 "${wordpress_dir}"  # 82 is www-data user in Alpine
    find "${wordpress_dir}" -type d -exec chmod 755 {} \;
    find "${wordpress_dir}" -type f -exec chmod 644 {} \;
    
    print_info "WordPress installation completed successfully!"
    echo ""
    echo "=========================================="
    echo "Site URL:       ${site_url}"
    echo "Admin Username: ${admin_user}"
    echo "Admin Password: ${admin_password}"
    echo "Admin Email:    ${admin_email}"
    echo "=========================================="
    echo ""
    print_warning "IMPORTANT: Save these credentials! The password will not be shown again."
    
    # Save credentials to a file
    local creds_file="${instance_dir}/wordpress-credentials.txt"
    cat > "$creds_file" << CREDS
WordPress Installation Credentials
===================================
Instance:       ${instance_name}
Site URL:       ${site_url}
Admin Username: ${admin_user}
Admin Password: ${admin_password}
Admin Email:    ${admin_email}
Database Name:  ${db_name}
Database User:  ${db_user}
Database Pass:  ${db_password}

Installation Date: $(date)
CREDS
    
    print_info "Credentials saved to: ${creds_file}"
}

# Main script
if [ $# -eq 0 ]; then
    echo "Usage: $0 <instance-name>"
    echo ""
    echo "Install latest WordPress version to an instance."
    echo ""
    echo "Example:"
    echo "  $0 mysite"
    exit 1
fi

install_wordpress "$1"
