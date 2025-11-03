# WordPress Docker-in-Docker (DinD) - Usage Guide

Complete guide for using the WordPress Docker-in-Docker setup with practical examples.

## Table of Contents

- [Getting Started](#getting-started)
- [Instance Management](#instance-management)
- [WordPress Installation](#wordpress-installation)
- [WP-CLI Usage](#wp-cli-usage)
- [Configuration Management](#configuration-management)
- [Log Management](#log-management)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)

---

## Getting Started

### Prerequisites

- Docker installed and running
- Docker Compose installed
- At least 4GB of available RAM
- 10GB of free disk space

### Initial Setup

#### 1. Build All Docker Images

Build all required images (PHP, MySQL, Nginx, Apache, and DinD):

```bash
cd /path/to/wordpress-docker-dind
./build-images.sh
```

This will build:
- PHP-FPM images: 7.4, 8.0, 8.1, 8.2, 8.3
- MySQL images: 5.6, 5.7, 8.0
- Nginx image: 1.27
- Apache image: 2.4
- DinD management image with WP-CLI, phpMyAdmin, and MailCatcher

**Build time:** ~15-30 minutes depending on your system.

#### 2. Start the DinD Container

```bash
docker-compose -f docker-compose-dind.yml up -d
```

#### 3. Verify the Setup

```bash
# Check if DinD container is running
docker ps | grep wordpress-dind-host

# Check DinD container health
docker exec wordpress-dind-host docker info

# Verify WP-CLI is available
docker exec wordpress-dind-host wp --info
```

#### 4. Access Management Tools

- **phpMyAdmin**: http://localhost:8080
- **MailCatcher**: http://localhost:1080

---

## Instance Management

### Creating WordPress Instances

The `instance-manager.sh` script manages WordPress instances with different configurations.

#### Basic Instance Creation

```bash
# Create instance with defaults (MySQL 8.0, PHP 8.3, Nginx)
docker exec wordpress-dind-host instance-manager.sh create mysite

# Create instance with specific versions
docker exec wordpress-dind-host instance-manager.sh create mysite 80 83 nginx
```

#### Version Options

**MySQL versions:**
- `56` - MySQL 5.6
- `57` - MySQL 5.7
- `80` - MySQL 8.0 (default)

**PHP versions:**
- `74` - PHP 7.4
- `80` - PHP 8.0
- `81` - PHP 8.1
- `82` - PHP 8.2
- `83` - PHP 8.3 (default)

**Web servers:**
- `nginx` - Nginx 1.27 (default)
- `apache` - Apache 2.4

#### Examples

```bash
# PHP 7.4 with MySQL 5.7 and Apache
docker exec wordpress-dind-host instance-manager.sh create legacy-site 57 74 apache

# PHP 8.2 with MySQL 8.0 and Nginx
docker exec wordpress-dind-host instance-manager.sh create modern-site 80 82 nginx

# Test environment with latest versions
docker exec wordpress-dind-host instance-manager.sh create test-env 80 83 nginx

# Staging environment
docker exec wordpress-dind-host instance-manager.sh create staging 80 83 nginx
```

### Managing Instances

#### Start an Instance

```bash
docker exec wordpress-dind-host instance-manager.sh start mysite
```

#### Stop an Instance

```bash
docker exec wordpress-dind-host instance-manager.sh stop mysite
```

#### List All Instances

```bash
docker exec wordpress-dind-host instance-manager.sh list
```

**Output example:**
```
Instance: mysite
  Status: running
  URL: http://localhost:8001
  MySQL: 8.0
  PHP: 8.3
  Web Server: nginx
  Network: wp-network-1
```

#### Get Instance Information

```bash
docker exec wordpress-dind-host instance-manager.sh info mysite
```

#### View Instance Logs

```bash
# View all logs
docker exec wordpress-dind-host instance-manager.sh logs mysite

# View specific service logs
docker exec wordpress-dind-host instance-manager.sh logs mysite php
docker exec wordpress-dind-host instance-manager.sh logs mysite mysql
docker exec wordpress-dind-host instance-manager.sh logs mysite nginx
```

#### Remove an Instance

```bash
# This will delete all data - use with caution!
docker exec wordpress-dind-host instance-manager.sh remove mysite
```

---

## WordPress Installation

### Using the Installation Script

The `install-wordpress.sh` script automatically installs the latest WordPress version.

#### Basic Installation

```bash
docker exec -it wordpress-dind-host /app/install-wordpress.sh mysite
```

#### Interactive Prompts

The script will ask for:

1. **Site Title** (default: "My WordPress Site")
2. **Admin Username** (default: "admin")
3. **Admin Email** (default: "admin@example.com")

The admin password is automatically generated and displayed.

#### Example Session

```bash
$ docker exec -it wordpress-dind-host /app/install-wordpress.sh mysite

[INFO] Downloading latest WordPress...
[INFO] Creating wp-config.php...
[INFO] Configuring WordPress settings...
[INFO] WordPress installation details:
Site Title [My WordPress Site]: My Awesome Blog
Admin Username [admin]: johndoe
Admin Email [admin@example.com]: john@example.com
[INFO] Installing WordPress...
[INFO] Setting file permissions...
[INFO] WordPress installation completed successfully!

==========================================
Site URL:       http://localhost:8001
Admin Username: johndoe
Admin Password: xK9mP2nQ7vR4sL8w
Admin Email:    john@example.com
==========================================

[WARNING] IMPORTANT: Save these credentials! The password will not be shown again.
[INFO] Credentials saved to: /wordpress-instances/mysite/wordpress-credentials.txt
```

#### Viewing Saved Credentials

```bash
docker exec wordpress-dind-host cat /wordpress-instances/mysite/wordpress-credentials.txt
```

#### Reinstalling WordPress

If WordPress is already installed, the script will prompt for confirmation:

```bash
$ docker exec -it wordpress-dind-host /app/install-wordpress.sh mysite

[WARNING] WordPress appears to be already installed in 'mysite'
Do you want to reinstall? This will DELETE all existing data! (yes/no): yes
[INFO] Removing existing WordPress installation...
[INFO] Downloading latest WordPress...
...
```

---

## WP-CLI Usage

WP-CLI is pre-installed in the DinD container. No `--allow-root` flag needed!

### Basic WP-CLI Commands

```bash
# Check WP-CLI version
docker exec wordpress-dind-host wp --info

# Set path variable for convenience
INSTANCE="mysite"
WP_PATH="/wordpress-instances/${INSTANCE}/data/wordpress"
```

### Plugin Management

#### List Plugins

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin list
```

#### Install and Activate Plugins

```bash
# Install and activate a plugin
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin install woocommerce --activate

# Install multiple plugins
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin install \
  contact-form-7 \
  yoast-seo \
  wordfence \
  --activate

# Install specific version
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin install \
  woocommerce --version=8.0.0 --activate
```

#### Deactivate and Uninstall Plugins

```bash
# Deactivate a plugin
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin deactivate woocommerce

# Uninstall a plugin
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin uninstall woocommerce --deactivate

# Deactivate all plugins
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin deactivate --all
```

#### Update Plugins

```bash
# Update all plugins
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin update --all

# Update specific plugin
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin update woocommerce
```

### Theme Management

#### List Themes

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress theme list
```

#### Install and Activate Themes

```bash
# Install and activate a theme
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress theme install twentytwentyfour --activate

# Install without activating
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress theme install astra
```

#### Update Themes

```bash
# Update all themes
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress theme update --all

# Update specific theme
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress theme update twentytwentyfour
```

### User Management

#### List Users

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user list
```

#### Create Users

```bash
# Create an administrator
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user create \
  bob bob@example.com --role=administrator --user_pass=SecurePass123

# Create an editor
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user create \
  alice alice@example.com --role=editor --user_pass=SecurePass456

# Create with random password (will be displayed)
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user create \
  charlie charlie@example.com --role=author
```

#### Update Users

```bash
# Update user email
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user update bob \
  --user_email=newemail@example.com

# Change user role
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user set-role bob editor

# Reset password
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user update bob \
  --user_pass=NewSecurePass123
```

#### Delete Users

```bash
# Delete user and reassign posts
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress user delete bob \
  --reassign=1
```

### Content Management

#### Create Posts

```bash
# Create a post
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress post create \
  --post_title="Hello World" \
  --post_content="This is my first post" \
  --post_status=publish

# Create a draft post
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress post create \
  --post_title="Draft Post" \
  --post_content="This is a draft" \
  --post_status=draft
```

#### List Posts

```bash
# List all posts
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress post list

# List published posts only
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress post list \
  --post_status=publish
```

#### Create Pages

```bash
# Create a page
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress post create \
  --post_type=page \
  --post_title="About Us" \
  --post_content="About our company" \
  --post_status=publish
```

### Database Operations

#### Export Database

```bash
# Export to file inside container
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress db export \
  /wordpress-instances/mysite/backup.sql

# Copy to host
docker cp wordpress-dind-host:/wordpress-instances/mysite/backup.sql ./mysite-backup.sql
```

#### Import Database

```bash
# Copy from host to container
docker cp ./mysite-backup.sql wordpress-dind-host:/wordpress-instances/mysite/import.sql

# Import
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress db import \
  /wordpress-instances/mysite/import.sql
```

#### Search and Replace

```bash
# Replace URLs (useful for migrations)
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress search-replace \
  'http://oldsite.com' 'http://localhost:8001' \
  --dry-run

# Execute the replacement
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress search-replace \
  'http://oldsite.com' 'http://localhost:8001'
```

### Core Updates

#### Check for Updates

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress core check-update
```

#### Update WordPress Core

```bash
# Update to latest version
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress core update

# Update to specific version
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress core update \
  --version=6.4.0
```

#### Verify Core Files

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress core verify-checksums
```

---

## Configuration Management

Configuration files are stored on the host and mounted into containers, allowing easy editing without rebuilding images.

### Directory Structure

```
config/
├── php/
│   ├── 7.4/
│   ├── 8.0/
│   ├── 8.1/
│   ├── 8.2/
│   └── 8.3/
├── mysql/
│   ├── 5.6/
│   ├── 5.7/
│   └── 8.0/
├── nginx/
│   └── 1.27/
└── apache/
    └── 2.4/
```

### PHP Configuration

#### Editing PHP Configuration Files

Configuration files are in `images/php/{version}/config/` and are baked into images. To override:

1. **Add host-level config** (affects all instances using that PHP version):

```bash
# Create config file on host
cat > config/php/8.3/custom-settings.ini << 'EOF'
; Custom PHP settings
memory_limit = 512M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 600
EOF

# Restart instances to apply
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

2. **Add instance-specific config** (affects only one instance):

```bash
# Edit instance-specific config
docker exec wordpress-dind-host vi /wordpress-instances/mysite/config/php-8.3/custom.ini

# Add your settings
memory_limit = 1024M
upload_max_filesize = 256M

# Restart instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

#### Enabling Xdebug

**Method 1: Enable for all instances using PHP 8.3**

```bash
# Edit host config
vi config/php/8.3/xdebug.ini

# Change mode from 'off' to 'debug'
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9003

# Restart all instances using PHP 8.3
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

**Method 2: Enable for a specific instance only**

```bash
# Edit instance-specific config
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/mysite/config/php-8.3/custom.ini << EOF
; Enable Xdebug for this instance
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.idekey=PHPSTORM
EOF'

# Restart instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

**Verify Xdebug is enabled:**

```bash
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress eval 'phpinfo();' | grep xdebug
```

### MySQL Configuration

#### Editing MySQL Configuration

**Host-level configuration** (affects all instances using that MySQL version):

```bash
# Create custom MySQL config
cat > config/mysql/8.0/custom.cnf << 'EOF'
[mysqld]
# Performance tuning
max_connections = 300
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M

# Query cache (MySQL 5.7 only)
# query_cache_type = 1
# query_cache_size = 64M

# Slow query log
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF

# Restart instances
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

**Instance-specific configuration:**

```bash
# Edit instance MySQL config
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/mysite/config/mysql-8.0/custom.cnf << EOF
[mysqld]
# Instance-specific settings
max_connections = 500
innodb_buffer_pool_size = 1G
EOF'

# Restart instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

**Verify MySQL configuration:**

```bash
docker exec wordpress-dind-host docker exec mysite-mysql mysql -uroot -p$(grep MYSQL_ROOT_PASSWORD /wordpress-instances/mysite/docker-compose.yml | awk '{print $2}') -e "SHOW VARIABLES LIKE 'max_connections';"
```

### Nginx Configuration

#### Editing Nginx Configuration

**Host-level configuration:**

```bash
# Edit Nginx config
vi config/nginx/1.27/wordpress.conf

# Example: Increase client_max_body_size
client_max_body_size 256M;

# Restart instances
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

**Test Nginx configuration:**

```bash
docker exec wordpress-dind-host docker exec mysite-nginx nginx -t
```

### Apache Configuration

#### Editing Apache Configuration

```bash
# Edit Apache config
vi config/apache/2.4/wordpress.conf

# Example: Add custom headers
Header set X-Custom-Header "MyValue"

# Restart instances
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

**Test Apache configuration:**

```bash
docker exec wordpress-dind-host docker exec mysite-apache apachectl configtest
```

---

## Log Management

All logs are stored on the host in the `logs/` directory, organized by instance and service.

### Log Directory Structure

```
logs/
├── mysite/
│   ├── php-8.3/
│   │   ├── error.log
│   │   └── access.log
│   ├── mysql-8.0/
│   │   ├── error.log
│   │   └── slow.log
│   └── nginx-1.27/
│       ├── access.log
│       └── error.log
└── legacy-site/
    ├── php-7.4/
    ├── mysql-5.7/
    └── apache-2.4/
```

### Viewing Logs from Host

#### PHP Logs

```bash
# View PHP error log
tail -f logs/mysite/php-8.3/error.log

# View last 100 lines
tail -n 100 logs/mysite/php-8.3/error.log

# Search for errors
grep "Fatal error" logs/mysite/php-8.3/error.log

# View logs with timestamps
tail -f logs/mysite/php-8.3/error.log | while read line; do echo "$(date '+%Y-%m-%d %H:%M:%S') $line"; done
```

#### MySQL Logs

```bash
# View MySQL error log
tail -f logs/mysite/mysql-8.0/error.log

# View slow query log
tail -f logs/mysite/mysql-8.0/slow.log

# Find slow queries
grep "Query_time" logs/mysite/mysql-8.0/slow.log
```

#### Nginx Logs

```bash
# View Nginx access log
tail -f logs/mysite/nginx-1.27/access.log

# View Nginx error log
tail -f logs/mysite/nginx-1.27/error.log

# Filter by status code
grep " 404 " logs/mysite/nginx-1.27/access.log
grep " 500 " logs/mysite/nginx-1.27/access.log

# Count requests by IP
awk '{print $1}' logs/mysite/nginx-1.27/access.log | sort | uniq -c | sort -rn | head -10
```

#### Apache Logs

```bash
# View Apache access log
tail -f logs/mysite/apache-2.4/access.log

# View Apache error log
tail -f logs/mysite/apache-2.4/error.log
```

### Viewing Logs from DinD Container

```bash
# Using instance-manager.sh
docker exec wordpress-dind-host instance-manager.sh logs mysite php
docker exec wordpress-dind-host instance-manager.sh logs mysite mysql
docker exec wordpress-dind-host instance-manager.sh logs mysite nginx

# Using docker logs
docker exec wordpress-dind-host docker logs mysite-php
docker exec wordpress-dind-host docker logs mysite-mysql
docker exec wordpress-dind-host docker logs mysite-nginx
```

### Log Rotation

To prevent logs from growing too large, set up log rotation on the host:

```bash
# Create logrotate config
sudo cat > /etc/logrotate.d/wordpress-dind << 'EOF'
/path/to/wordpress-docker-dind/logs/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 www-data www-data
    sharedscripts
}
EOF
```

---

## Common Workflows

### Workflow 1: Setting Up a Development Environment with Xdebug

Complete setup for PHP development with debugging:

```bash
# 1. Create instance
docker exec wordpress-dind-host instance-manager.sh create dev-site 80 83 nginx

# 2. Install WordPress
docker exec -it wordpress-dind-host /app/install-wordpress.sh dev-site

# 3. Enable Xdebug for this instance
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/dev-site/config/php-8.3/custom.ini << EOF
; Xdebug configuration
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.idekey=PHPSTORM
xdebug.log=/var/log/php/xdebug.log

; Development settings
display_errors=On
error_reporting=E_ALL
EOF'

# 4. Increase memory and upload limits
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/dev-site/config/php-8.3/custom.ini << EOF
memory_limit=512M
upload_max_filesize=128M
post_max_size=128M
max_execution_time=300
EOF'

# 5. Restart instance
docker exec wordpress-dind-host instance-manager.sh stop dev-site
docker exec wordpress-dind-host instance-manager.sh start dev-site

# 6. Install development plugins
docker exec wordpress-dind-host wp --path=/wordpress-instances/dev-site/data/wordpress plugin install \
  query-monitor \
  debug-bar \
  --activate

# 7. Enable WordPress debug mode
docker exec wordpress-dind-host wp --path=/wordpress-instances/dev-site/data/wordpress config set WP_DEBUG true --raw
docker exec wordpress-dind-host wp --path=/wordpress-instances/dev-site/data/wordpress config set WP_DEBUG_LOG true --raw
docker exec wordpress-dind-host wp --path=/wordpress-instances/dev-site/data/wordpress config set WP_DEBUG_DISPLAY true --raw

# 8. Get instance info
docker exec wordpress-dind-host instance-manager.sh info dev-site
```

### Workflow 2: Testing a Plugin Across Multiple PHP Versions

Test plugin compatibility across different PHP versions:

```bash
# 1. Create instances with different PHP versions
docker exec wordpress-dind-host instance-manager.sh create test-php74 80 74 nginx
docker exec wordpress-dind-host instance-manager.sh create test-php80 80 80 nginx
docker exec wordpress-dind-host instance-manager.sh create test-php81 80 81 nginx
docker exec wordpress-dind-host instance-manager.sh create test-php82 80 82 nginx
docker exec wordpress-dind-host instance-manager.sh create test-php83 80 83 nginx

# 2. Install WordPress on all instances
for instance in test-php74 test-php80 test-php81 test-php82 test-php83; do
  docker exec -it wordpress-dind-host /app/install-wordpress.sh $instance
done

# 3. Copy your plugin to each instance
for instance in test-php74 test-php80 test-php81 test-php82 test-php83; do
  docker cp ./my-plugin wordpress-dind-host:/wordpress-instances/$instance/data/wordpress/wp-content/plugins/
done

# 4. Activate plugin on all instances
for instance in test-php74 test-php80 test-php81 test-php82 test-php83; do
  docker exec wordpress-dind-host wp --path=/wordpress-instances/$instance/data/wordpress plugin activate my-plugin
done

# 5. Check for PHP errors in each instance
for instance in test-php74 test-php80 test-php81 test-php82 test-php83; do
  echo "=== $instance ==="
  tail -n 50 logs/$instance/php-*/error.log | grep -i "fatal\|error\|warning" || echo "No errors found"
done

# 6. List instances with URLs
docker exec wordpress-dind-host instance-manager.sh list
```

### Workflow 3: Migrating an Existing WordPress Site

Import an existing WordPress site into an instance:

```bash
# 1. Create instance
docker exec wordpress-dind-host instance-manager.sh create imported-site 80 83 nginx

# 2. Install WordPress (we'll replace it)
docker exec -it wordpress-dind-host /app/install-wordpress.sh imported-site

# 3. Copy database dump to container
docker cp ./site-backup.sql wordpress-dind-host:/wordpress-instances/imported-site/

# 4. Import database
docker exec wordpress-dind-host wp --path=/wordpress-instances/imported-site/data/wordpress db import \
  /wordpress-instances/imported-site/site-backup.sql

# 5. Copy WordPress files
docker cp ./wordpress-files/. wordpress-dind-host:/wordpress-instances/imported-site/data/wordpress/

# 6. Get the new site URL
NEW_URL=$(docker exec wordpress-dind-host instance-manager.sh info imported-site | grep "URL:" | awk '{print $2}')

# 7. Search and replace URLs
docker exec wordpress-dind-host wp --path=/wordpress-instances/imported-site/data/wordpress search-replace \
  'https://oldsite.com' "$NEW_URL" \
  --dry-run

# If dry-run looks good, execute
docker exec wordpress-dind-host wp --path=/wordpress-instances/imported-site/data/wordpress search-replace \
  'https://oldsite.com' "$NEW_URL"

# 8. Fix file permissions
docker exec wordpress-dind-host chown -R 82:82 /wordpress-instances/imported-site/data/wordpress

# 9. Flush cache
docker exec wordpress-dind-host wp --path=/wordpress-instances/imported-site/data/wordpress cache flush

# 10. Verify site
echo "Site available at: $NEW_URL"
```

### Workflow 4: Creating a Staging Environment

Clone a production site for staging:

```bash
# 1. Export production database
docker exec wordpress-dind-host wp --path=/wordpress-instances/production/data/wordpress db export \
  /wordpress-instances/production/staging-backup.sql

# 2. Create staging instance
docker exec wordpress-dind-host instance-manager.sh create staging 80 83 nginx

# 3. Install WordPress
docker exec -it wordpress-dind-host /app/install-wordpress.sh staging

# 4. Copy production files to staging
docker exec wordpress-dind-host cp -r /wordpress-instances/production/data/wordpress/* \
  /wordpress-instances/staging/data/wordpress/

# 5. Import production database
docker exec wordpress-dind-host wp --path=/wordpress-instances/staging/data/wordpress db import \
  /wordpress-instances/production/staging-backup.sql

# 6. Get staging URL
STAGING_URL=$(docker exec wordpress-dind-host instance-manager.sh info staging | grep "URL:" | awk '{print $2}')
PROD_URL=$(docker exec wordpress-dind-host instance-manager.sh info production | grep "URL:" | awk '{print $2}')

# 7. Update URLs
docker exec wordpress-dind-host wp --path=/wordpress-instances/staging/data/wordpress search-replace \
  "$PROD_URL" "$STAGING_URL"

# 8. Disable production plugins (optional)
docker exec wordpress-dind-host wp --path=/wordpress-instances/staging/data/wordpress plugin deactivate \
  google-analytics \
  jetpack

# 9. Enable staging-specific settings
docker exec wordpress-dind-host wp --path=/wordpress-instances/staging/data/wordpress config set WP_ENVIRONMENT_TYPE 'staging'

# 10. Verify
echo "Staging site available at: $STAGING_URL"
```

### Workflow 5: Performance Testing with Different Configurations

Test WordPress performance with different MySQL and PHP versions:

```bash
# 1. Create instances with different configurations
docker exec wordpress-dind-host instance-manager.sh create perf-mysql56 56 83 nginx
docker exec wordpress-dind-host instance-manager.sh create perf-mysql57 57 83 nginx
docker exec wordpress-dind-host instance-manager.sh create perf-mysql80 80 83 nginx

# 2. Install WordPress on all
for instance in perf-mysql56 perf-mysql57 perf-mysql80; do
  docker exec -it wordpress-dind-host /app/install-wordpress.sh $instance
done

# 3. Install performance testing plugin
for instance in perf-mysql56 perf-mysql57 perf-mysql80; do
  docker exec wordpress-dind-host wp --path=/wordpress-instances/$instance/data/wordpress plugin install \
    query-monitor --activate
done

# 4. Import sample content
for instance in perf-mysql56 perf-mysql57 perf-mysql80; do
  docker exec wordpress-dind-host wp --path=/wordpress-instances/$instance/data/wordpress plugin install \
    wordpress-importer --activate
  # Import sample data here
done

# 5. Monitor query performance
for instance in perf-mysql56 perf-mysql57 perf-mysql80; do
  echo "=== $instance ==="
  tail -f logs/$instance/mysql-*/slow.log &
done
```

### Workflow 6: Multi-Site Network Setup

Create a WordPress multisite network:

```bash
# 1. Create instance
docker exec wordpress-dind-host instance-manager.sh create multisite 80 83 nginx

# 2. Install WordPress
docker exec -it wordpress-dind-host /app/install-wordpress.sh multisite

# 3. Enable multisite
docker exec wordpress-dind-host wp --path=/wordpress-instances/multisite/data/wordpress core multisite-convert

# 4. Update wp-config.php with multisite constants (already done by WP-CLI)

# 5. Create additional sites
docker exec wordpress-dind-host wp --path=/wordpress-instances/multisite/data/wordpress site create \
  --slug=blog1 --title="Blog 1" --email=admin@blog1.com

docker exec wordpress-dind-host wp --path=/wordpress-instances/multisite/data/wordpress site create \
  --slug=blog2 --title="Blog 2" --email=admin@blog2.com

# 6. List all sites
docker exec wordpress-dind-host wp --path=/wordpress-instances/multisite/data/wordpress site list

# 7. Activate plugin network-wide
docker exec wordpress-dind-host wp --path=/wordpress-instances/multisite/data/wordpress plugin install \
  akismet --activate-network
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Instance Won't Start

**Symptoms:**
- Instance fails to start
- Containers exit immediately

**Diagnosis:**

```bash
# Check container status
docker exec wordpress-dind-host docker ps -a | grep mysite

# Check container logs
docker exec wordpress-dind-host docker logs mysite-mysql
docker exec wordpress-dind-host docker logs mysite-php
docker exec wordpress-dind-host docker logs mysite-nginx

# Check instance directory
docker exec wordpress-dind-host ls -la /wordpress-instances/mysite
```

**Solutions:**

```bash
# 1. Check if ports are already in use
docker exec wordpress-dind-host docker ps | grep "0.0.0.0"

# 2. Restart the instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite

# 3. Check docker-compose.yml for errors
docker exec wordpress-dind-host cat /wordpress-instances/mysite/docker-compose.yml

# 4. Recreate the instance if necessary
docker exec wordpress-dind-host instance-manager.sh remove mysite
docker exec wordpress-dind-host instance-manager.sh create mysite
```

#### Issue 2: Cannot Connect to Database

**Symptoms:**
- "Error establishing a database connection"
- WordPress shows database error

**Diagnosis:**

```bash
# Check if MySQL container is running
docker exec wordpress-dind-host docker ps | grep mysite-mysql

# Check MySQL logs
docker exec wordpress-dind-host docker logs mysite-mysql

# Test MySQL connection
docker exec wordpress-dind-host docker exec mysite-mysql mysql -uwordpress -p
```

**Solutions:**

```bash
# 1. Verify database credentials in wp-config.php
docker exec wordpress-dind-host cat /wordpress-instances/mysite/data/wordpress/wp-config.php | grep DB_

# 2. Verify credentials in docker-compose.yml
docker exec wordpress-dind-host cat /wordpress-instances/mysite/docker-compose.yml | grep MYSQL

# 3. Restart MySQL container
docker exec wordpress-dind-host docker restart mysite-mysql

# 4. Check MySQL data directory permissions
docker exec wordpress-dind-host ls -la /wordpress-instances/mysite/data/mysql

# 5. Reset database (WARNING: deletes all data)
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host rm -rf /wordpress-instances/mysite/data/mysql/*
docker exec wordpress-dind-host instance-manager.sh start mysite
```

#### Issue 3: File Upload Errors

**Symptoms:**
- "The uploaded file exceeds the upload_max_filesize directive"
- Large files fail to upload

**Solutions:**

```bash
# 1. Check current PHP limits
docker exec wordpress-dind-host docker exec mysite-php php -i | grep upload_max_filesize
docker exec wordpress-dind-host docker exec mysite-php php -i | grep post_max_size

# 2. Increase PHP upload limits
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/mysite/config/php-8.3/custom.ini << EOF
upload_max_filesize = 256M
post_max_size = 256M
memory_limit = 512M
EOF'

# 3. Increase Nginx client_max_body_size (if using Nginx)
docker exec wordpress-dind-host sh -c 'cat > /wordpress-instances/mysite/nginx-custom.conf << EOF
client_max_body_size 256M;
EOF'

# 4. Restart instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite

# 5. Verify changes
docker exec wordpress-dind-host docker exec mysite-php php -i | grep upload_max_filesize
```

#### Issue 4: Xdebug Not Working

**Symptoms:**
- Breakpoints not hit
- IDE not connecting to Xdebug

**Diagnosis:**

```bash
# 1. Check if Xdebug is loaded
docker exec wordpress-dind-host docker exec mysite-php php -m | grep xdebug

# 2. Check Xdebug configuration
docker exec wordpress-dind-host docker exec mysite-php php -i | grep xdebug

# 3. Check Xdebug log
tail -f logs/mysite/php-8.3/xdebug.log
```

**Solutions:**

```bash
# 1. Verify Xdebug is enabled in config
docker exec wordpress-dind-host cat /wordpress-instances/mysite/config/php-8.3/custom.ini | grep xdebug

# 2. Enable Xdebug if not enabled
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/mysite/config/php-8.3/custom.ini << EOF
xdebug.mode=debug
xdebug.start_with_request=yes
xdebug.client_host=host.docker.internal
xdebug.client_port=9003
xdebug.log=/var/log/php/xdebug.log
EOF'

# 3. Restart instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite

# 4. Test Xdebug connection
docker exec wordpress-dind-host docker exec mysite-php php -r "xdebug_info();"

# 5. Check firewall settings on host
# Ensure port 9003 is not blocked
```

#### Issue 5: Slow Performance

**Symptoms:**
- WordPress loads slowly
- Database queries are slow

**Diagnosis:**

```bash
# 1. Check MySQL slow query log
tail -f logs/mysite/mysql-8.0/slow.log

# 2. Install Query Monitor plugin
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin install \
  query-monitor --activate

# 3. Check PHP-FPM status
docker exec wordpress-dind-host docker exec mysite-php php-fpm -t

# 4. Check resource usage
docker exec wordpress-dind-host docker stats mysite-mysql mysite-php mysite-nginx
```

**Solutions:**

```bash
# 1. Enable OPcache (should be enabled by default)
docker exec wordpress-dind-host docker exec mysite-php php -i | grep opcache.enable

# 2. Increase MySQL buffer pool
docker exec wordpress-dind-host sh -c 'cat >> /wordpress-instances/mysite/config/mysql-8.0/custom.cnf << EOF
[mysqld]
innodb_buffer_pool_size = 512M
innodb_log_file_size = 128M
max_connections = 200
EOF'

# 3. Install caching plugin
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress plugin install \
  w3-total-cache --activate

# 4. Optimize database
docker exec wordpress-dind-host wp --path=/wordpress-instances/mysite/data/wordpress db optimize

# 5. Restart instance
docker exec wordpress-dind-host instance-manager.sh stop mysite
docker exec wordpress-dind-host instance-manager.sh start mysite
```

#### Issue 6: Permission Errors

**Symptoms:**
- "Unable to create directory"
- "Permission denied" errors

**Solutions:**

```bash
# 1. Fix WordPress file permissions
docker exec wordpress-dind-host chown -R 82:82 /wordpress-instances/mysite/data/wordpress
docker exec wordpress-dind-host find /wordpress-instances/mysite/data/wordpress -type d -exec chmod 755 {} \;
docker exec wordpress-dind-host find /wordpress-instances/mysite/data/wordpress -type f -exec chmod 644 {} \;

# 2. Fix wp-content permissions
docker exec wordpress-dind-host chmod -R 775 /wordpress-instances/mysite/data/wordpress/wp-content

# 3. Verify permissions
docker exec wordpress-dind-host ls -la /wordpress-instances/mysite/data/wordpress
```

#### Issue 7: DinD Container Won't Start

**Symptoms:**
- DinD container exits immediately
- Cannot connect to Docker daemon

**Diagnosis:**

```bash
# Check container logs
docker logs wordpress-dind-host

# Check if privileged mode is enabled
docker inspect wordpress-dind-host | grep Privileged
```

**Solutions:**

```bash
# 1. Ensure privileged mode is set in docker-compose-dind.yml
grep "privileged: true" docker-compose-dind.yml

# 2. Restart DinD container
docker-compose -f docker-compose-dind.yml down
docker-compose -f docker-compose-dind.yml up -d

# 3. Check Docker daemon inside DinD
docker exec wordpress-dind-host docker info

# 4. If still failing, remove volumes and restart
docker-compose -f docker-compose-dind.yml down -v
docker-compose -f docker-compose-dind.yml up -d
```

#### Issue 8: Cannot Access phpMyAdmin

**Symptoms:**
- phpMyAdmin not accessible at http://localhost:8080
- Connection refused

**Solutions:**

```bash
# 1. Check if DinD container is running
docker ps | grep wordpress-dind-host

# 2. Check if port 8080 is mapped
docker port wordpress-dind-host 8080

# 3. Check phpMyAdmin logs inside DinD
docker exec wordpress-dind-host supervisorctl status phpmyadmin
docker exec wordpress-dind-host tail -f /var/log/supervisor/phpmyadmin-*.log

# 4. Restart phpMyAdmin
docker exec wordpress-dind-host supervisorctl restart phpmyadmin

# 5. Check Nginx configuration for phpMyAdmin
docker exec wordpress-dind-host cat /etc/nginx/http.d/phpmyadmin.conf
```

### Getting Help

If you encounter issues not covered here:

1. **Check logs:**
   ```bash
   # DinD container logs
   docker logs wordpress-dind-host

   # Instance logs
   docker exec wordpress-dind-host instance-manager.sh logs mysite

   # Host logs
   tail -f logs/mysite/*/*.log
   ```

2. **Verify configuration:**
   ```bash
   # Check instance configuration
   docker exec wordpress-dind-host cat /wordpress-instances/mysite/docker-compose.yml

   # Check PHP configuration
   docker exec wordpress-dind-host docker exec mysite-php php -i

   # Check MySQL configuration
   docker exec wordpress-dind-host docker exec mysite-mysql mysql --help
   ```

3. **Test connectivity:**
   ```bash
   # Test if containers can communicate
   docker exec wordpress-dind-host docker exec mysite-php ping -c 3 mysite-mysql

   # Test database connection
   docker exec wordpress-dind-host docker exec mysite-php nc -zv mysite-mysql 3306
   ```

---

## Advanced Tips

### Creating Bash Aliases

Add these to your `~/.bashrc` or `~/.zshrc` for easier management:

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

**Usage:**

```bash
# Create instance
wp-instance create mysite

# Install WordPress
wp-install mysite

# Use WP-CLI
wp-cli mysite plugin list
wp-cli mysite theme install astra --activate

# View logs
wp-logs mysite php
wp-logs mysite mysql

# Quick create and install
wp-create quicksite
```

### Backup and Restore

#### Backup Script

```bash
#!/bin/bash
# backup-instance.sh

INSTANCE=$1
BACKUP_DIR="./backups/$(date +%Y%m%d-%H%M%S)-$INSTANCE"

mkdir -p "$BACKUP_DIR"

# Backup database
docker exec wordpress-dind-host wp --path=/wordpress-instances/$INSTANCE/data/wordpress db export \
  /wordpress-instances/$INSTANCE/backup.sql

docker cp wordpress-dind-host:/wordpress-instances/$INSTANCE/backup.sql "$BACKUP_DIR/"

# Backup WordPress files
docker exec wordpress-dind-host tar -czf /wordpress-instances/$INSTANCE/wordpress-files.tar.gz \
  -C /wordpress-instances/$INSTANCE/data wordpress

docker cp wordpress-dind-host:/wordpress-instances/$INSTANCE/wordpress-files.tar.gz "$BACKUP_DIR/"

# Backup configuration
docker cp wordpress-dind-host:/wordpress-instances/$INSTANCE/docker-compose.yml "$BACKUP_DIR/"
docker cp wordpress-dind-host:/wordpress-instances/$INSTANCE/config "$BACKUP_DIR/" -r

echo "Backup completed: $BACKUP_DIR"
```

#### Restore Script

```bash
#!/bin/bash
# restore-instance.sh

INSTANCE=$1
BACKUP_DIR=$2

# Stop instance
docker exec wordpress-dind-host instance-manager.sh stop $INSTANCE

# Restore database
docker cp "$BACKUP_DIR/backup.sql" wordpress-dind-host:/wordpress-instances/$INSTANCE/
docker exec wordpress-dind-host wp --path=/wordpress-instances/$INSTANCE/data/wordpress db import \
  /wordpress-instances/$INSTANCE/backup.sql

# Restore WordPress files
docker cp "$BACKUP_DIR/wordpress-files.tar.gz" wordpress-dind-host:/wordpress-instances/$INSTANCE/
docker exec wordpress-dind-host tar -xzf /wordpress-instances/$INSTANCE/wordpress-files.tar.gz \
  -C /wordpress-instances/$INSTANCE/data

# Start instance
docker exec wordpress-dind-host instance-manager.sh start $INSTANCE

echo "Restore completed: $INSTANCE"
```

---

## Additional Resources

### Useful WP-CLI Commands Reference

```bash
# Core
wp core version                    # Check WordPress version
wp core update                     # Update WordPress
wp core verify-checksums           # Verify core files

# Database
wp db query "SELECT * FROM wp_options WHERE option_name='siteurl'"
wp db optimize                     # Optimize database
wp db repair                       # Repair database

# Cache
wp cache flush                     # Flush object cache
wp transient delete --all          # Delete all transients
wp rewrite flush                   # Flush rewrite rules

# Media
wp media regenerate --yes          # Regenerate thumbnails

# Cron
wp cron event list                 # List cron events
wp cron event run --all            # Run all cron events

# Config
wp config get DB_NAME              # Get config value
wp config set WP_DEBUG true --raw  # Set config value

# Maintenance
wp maintenance-mode activate       # Enable maintenance mode
wp maintenance-mode deactivate     # Disable maintenance mode
```

### Port Mapping Reference

- **8000-8099**: WordPress instances (auto-assigned)
- **8080**: phpMyAdmin
- **1080**: MailCatcher Web UI
- **1025**: MailCatcher SMTP
- **2375**: Docker daemon (DinD)

### File Locations

- **Instances**: `/wordpress-instances/` (inside DinD)
- **Logs**: `./logs/` (on host)
- **Config**: `./config/` (on host)
- **Shared Images**: `./shared-images/` (on host)

---

## Conclusion

This guide covers the most common use cases for the WordPress Docker-in-Docker setup. For more advanced scenarios or custom configurations, refer to the individual component documentation or examine the source code in the `images/` directory.

**Happy WordPress development!** 🚀

