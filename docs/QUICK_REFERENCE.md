# WordPress Docker-in-Docker - Quick Reference

Fast reference guide for common commands and operations.

## Table of Contents

- [Setup](#setup)
- [Instance Management](#instance-management)
- [WordPress Installation](#wordpress-installation)
- [WP-CLI Commands](#wp-cli-commands)
- [Configuration](#configuration)
- [Logs](#logs)
- [Useful Aliases](#useful-aliases)

---

## Setup

```bash
# Build all images
./build-images.sh

# Start DinD container
docker-compose -f docker-compose-dind.yml up -d

# Stop DinD container
docker-compose -f docker-compose-dind.yml down

# Restart DinD container
docker-compose -f docker-compose-dind.yml restart

# View DinD logs
docker logs -f wordpress-dind-host
```

---

## Instance Management

### Create Instance

```bash
# Default (MySQL 8.0, PHP 8.3, Nginx)
docker exec wordpress-dind-host instance-manager.sh create INSTANCE_NAME

# Custom versions
docker exec wordpress-dind-host instance-manager.sh create INSTANCE_NAME MYSQL_VER PHP_VER WEBSERVER

# Examples
docker exec wordpress-dind-host instance-manager.sh create mysite 80 83 nginx
docker exec wordpress-dind-host instance-manager.sh create legacy 57 74 apache
```

**Version Options:**
- MySQL: `56`, `57`, `80`
- PHP: `74`, `80`, `81`, `82`, `83`
- Web Server: `nginx`, `apache`

### Manage Instances

```bash
# List all instances
docker exec wordpress-dind-host instance-manager.sh list

# Get instance info
docker exec wordpress-dind-host instance-manager.sh info INSTANCE_NAME

# Start instance
docker exec wordpress-dind-host instance-manager.sh start INSTANCE_NAME

# Stop instance
docker exec wordpress-dind-host instance-manager.sh stop INSTANCE_NAME

# Remove instance (deletes all data!)
docker exec wordpress-dind-host instance-manager.sh remove INSTANCE_NAME

# View instance logs
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME php
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME mysql
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME nginx
```

---

## WordPress Installation

```bash
# Install WordPress on instance
docker exec -it wordpress-dind-host /app/install-wordpress.sh INSTANCE_NAME

# View saved credentials
docker exec wordpress-dind-host cat /wordpress-instances/INSTANCE_NAME/wordpress-credentials.txt
```

---

## WP-CLI Commands

**Note:** No `--allow-root` flag needed!

### Basic Format

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/INSTANCE_NAME/data/wordpress COMMAND
```

### Core

```bash
# Check version
wp --path=/wordpress-instances/INSTANCE/data/wordpress core version

# Update WordPress
wp --path=/wordpress-instances/INSTANCE/data/wordpress core update

# Verify checksums
wp --path=/wordpress-instances/INSTANCE/data/wordpress core verify-checksums
```

### Plugins

```bash
# List plugins
wp --path=/wordpress-instances/INSTANCE/data/wordpress plugin list

# Install plugin
wp --path=/wordpress-instances/INSTANCE/data/wordpress plugin install PLUGIN_NAME --activate

# Update all plugins
wp --path=/wordpress-instances/INSTANCE/data/wordpress plugin update --all

# Deactivate plugin
wp --path=/wordpress-instances/INSTANCE/data/wordpress plugin deactivate PLUGIN_NAME

# Uninstall plugin
wp --path=/wordpress-instances/INSTANCE/data/wordpress plugin uninstall PLUGIN_NAME --deactivate
```

### Themes

```bash
# List themes
wp --path=/wordpress-instances/INSTANCE/data/wordpress theme list

# Install theme
wp --path=/wordpress-instances/INSTANCE/data/wordpress theme install THEME_NAME --activate

# Update all themes
wp --path=/wordpress-instances/INSTANCE/data/wordpress theme update --all
```

### Users

```bash
# List users
wp --path=/wordpress-instances/INSTANCE/data/wordpress user list

# Create user
wp --path=/wordpress-instances/INSTANCE/data/wordpress user create USERNAME EMAIL --role=ROLE

# Update user
wp --path=/wordpress-instances/INSTANCE/data/wordpress user update USERNAME --user_pass=PASSWORD

# Delete user
wp --path=/wordpress-instances/INSTANCE/data/wordpress user delete USERNAME --reassign=1
```

### Database

```bash
# Export database
wp --path=/wordpress-instances/INSTANCE/data/wordpress db export /wordpress-instances/INSTANCE/backup.sql

# Import database
wp --path=/wordpress-instances/INSTANCE/data/wordpress db import /wordpress-instances/INSTANCE/backup.sql

# Search and replace
wp --path=/wordpress-instances/INSTANCE/data/wordpress search-replace 'old-url.com' 'new-url.com'

# Optimize database
wp --path=/wordpress-instances/INSTANCE/data/wordpress db optimize
```

### Cache & Maintenance

```bash
# Flush cache
wp --path=/wordpress-instances/INSTANCE/data/wordpress cache flush

# Flush rewrite rules
wp --path=/wordpress-instances/INSTANCE/data/wordpress rewrite flush

# Enable maintenance mode
wp --path=/wordpress-instances/INSTANCE/data/wordpress maintenance-mode activate

# Disable maintenance mode
wp --path=/wordpress-instances/INSTANCE/data/wordpress maintenance-mode deactivate
```

---

## Configuration

### PHP Configuration

**Host-level (affects all instances using that PHP version):**

```bash
# Edit config file
vi config/php/8.3/custom-settings.ini

# Restart instances
docker exec wordpress-dind-host instance-manager.sh stop INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh start INSTANCE_NAME
```

**Instance-level (affects only one instance):**

```bash
# Edit instance config
docker exec wordpress-dind-host vi /wordpress-instances/INSTANCE_NAME/config/php-8.3/custom.ini

# Restart instance
docker exec wordpress-dind-host instance-manager.sh stop INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh start INSTANCE_NAME
```

### Enable Xdebug

```bash
# Instance-specific
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/INSTANCE_NAME/config/php-8.3/custom.ini << EOF
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
EOF'

# Restart instance
docker exec wordpress-dind-host instance-manager.sh stop INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh start INSTANCE_NAME
```

### MySQL Configuration

```bash
# Instance-specific
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/INSTANCE_NAME/config/mysql-8.0/custom.cnf << EOF
[mysqld]
max_connections = 300
innodb_buffer_pool_size = 512M
EOF'

# Restart instance
docker exec wordpress-dind-host instance-manager.sh stop INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh start INSTANCE_NAME
```

---

## Logs

### View Logs from Host

```bash
# PHP error log
tail -f logs/INSTANCE_NAME/php-8.3/error.log

# MySQL error log
tail -f logs/INSTANCE_NAME/mysql-8.0/error.log

# Nginx access log
tail -f logs/INSTANCE_NAME/nginx-1.27/access.log

# Nginx error log
tail -f logs/INSTANCE_NAME/nginx-1.27/error.log

# Apache access log
tail -f logs/INSTANCE_NAME/apache-2.4/access.log

# Apache error log
tail -f logs/INSTANCE_NAME/apache-2.4/error.log
```

### View Logs from DinD

```bash
# Using instance-manager
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME php
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME mysql
docker exec wordpress-dind-host instance-manager.sh logs INSTANCE_NAME nginx

# Using docker logs
docker exec wordpress-dind-host docker logs INSTANCE_NAME-php
docker exec wordpress-dind-host docker logs INSTANCE_NAME-mysql
docker exec wordpress-dind-host docker logs INSTANCE_NAME-nginx
```

---

## Useful Aliases

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# WordPress DinD aliases
alias wp-dind='docker exec wordpress-dind-host'
alias wp-instance='docker exec wordpress-dind-host instance-manager.sh'
alias wp-install='docker exec -it wordpress-dind-host /app/install-wordpress.sh'

# WP-CLI shortcut
wp-cli() {
  local instance=$1
  shift
  docker exec wordpress-dind-host wp --path=/wordpress-instances/$instance/data/wordpress "$@"
}

# Log viewer
wp-logs() {
  local instance=$1
  local service=${2:-php}
  tail -f logs/$instance/$service-*/error.log
}

# Quick instance creation
wp-create() {
  local name=$1
  docker exec wordpress-dind-host instance-manager.sh create $name
  docker exec -it wordpress-dind-host /app/install-wordpress.sh $name
}
```

**Usage after adding aliases:**

```bash
# Create instance
wp-instance create mysite

# Install WordPress
wp-install mysite

# Use WP-CLI
wp-cli mysite plugin list
wp-cli mysite theme install astra --activate
wp-cli mysite user create bob bob@example.com --role=editor

# View logs
wp-logs mysite php
wp-logs mysite mysql

# Quick create and install
wp-create quicksite
```

---

## Common Workflows

### Quick Setup

```bash
# 1. Create instance
docker exec wordpress-dind-host instance-manager.sh create mysite

# 2. Install WordPress
docker exec -it wordpress-dind-host /app/install-wordpress.sh mysite

# 3. Get URL
docker exec wordpress-dind-host instance-manager.sh info mysite
```

### Enable Development Mode

```bash
# Enable Xdebug and debug mode
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/mysite/config/php-8.3/custom.ini << EOF
xdebug.mode=debug
xdebug.start_with_request=yes
display_errors=On
error_reporting=E_ALL
memory_limit=512M
EOF'

# Enable WordPress debug
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress config set WP_DEBUG true --raw
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress config set WP_DEBUG_LOG true --raw

# Restart
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

### Backup Instance

```bash
# Export database
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress db export \
  /wordpress-instances/mysite/backup.sql

# Copy to host
docker cp wordpress-dind-host:/wordpress-instances/mysite/backup.sql ./mysite-backup.sql

# Backup files
docker exec wordpress-dind-host tar -czf /wordpress-instances/mysite/files.tar.gz \
  -C /wordpress-instances/mysite/data wordpress

docker cp wordpress-dind-host:/wordpress-instances/mysite/files.tar.gz ./mysite-files.tar.gz
```

### Restore Instance

```bash
# Copy database to container
docker cp ./mysite-backup.sql wordpress-dind-host:/wordpress-instances/mysite/

# Import database
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress db import \
  /wordpress-instances/mysite/mysite-backup.sql

# Copy files to container
docker cp ./mysite-files.tar.gz wordpress-dind-host:/wordpress-instances/mysite/

# Extract files
docker exec wordpress-dind-host tar -xzf /wordpress-instances/mysite/files.tar.gz \
  -C /wordpress-instances/mysite/data
```

---

## Access Points

- **WordPress Instances**: http://localhost:8000-8099 (auto-assigned)
- **phpMyAdmin**: http://localhost:8080
- **MailCatcher**: http://localhost:1080
- **Docker Daemon**: localhost:2375

---

## File Locations

- **Instances**: `/wordpress-instances/` (inside DinD)
- **Logs**: `./logs/` (on host)
- **Config**: `./config/` (on host)
- **Credentials**: `/wordpress-instances/INSTANCE_NAME/wordpress-credentials.txt`

---

## Troubleshooting Quick Fixes

```bash
# Instance won't start
docker exec wordpress-dind-host instance-manager.sh stop INSTANCE_NAME
docker exec wordpress-dind-host instance-manager.sh start INSTANCE_NAME

# Database connection error
docker exec wordpress-dind-host docker restart INSTANCE_NAME-mysql

# Fix file permissions
docker exec wordpress-dind-host chown -R 82:82 /wordpress-instances/INSTANCE_NAME/data/wordpress

# Clear all caches
docker exec wordpress-dind-host wp --path=/wordpress-instances/INSTANCE_NAME/data/wordpress cache flush
docker exec wordpress-dind-host wp --path=/wordpress-instances/INSTANCE_NAME/data/wordpress rewrite flush
docker exec wordpress-dind-host wp --path=/wordpress-instances/INSTANCE_NAME/data/wordpress transient delete --all

# Restart DinD container
docker-compose -f docker-compose-dind.yml restart
```

---

For detailed documentation, see [USAGE.md](USAGE.md)

