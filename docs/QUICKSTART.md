# Quick Start Guide

Get up and running with WordPress Docker-in-Docker in 5 minutes!

## Prerequisites

- Docker 20.10+
- docker-compose 1.29+
- Node.js 18.0+

## Installation (5 Steps)

### 1. Build Images (5-10 minutes)

```bash
chmod +x build-images.sh
./build-images.sh
```

### 2. Install CLI Tool (1 minute)

```bash
cd cli-tool
npm install -g .
cd ..
```

### 3. Initialize Environment (30 seconds)

```bash
mkdir ~/my-wordpress-project
cd ~/my-wordpress-project
wp-dind init
```

### 4. Start Environment (1 minute)

```bash
wp-dind start
```

### 5. Create WordPress Instance (2 minutes)

```bash
# Create instance with default settings (MySQL 8.0, PHP 8.3, Nginx)
wp-dind exec instance-manager.sh create mysite

# Or create with custom configuration
# Syntax: create <name> [mysql_version] [php_version] [webserver]
wp-dind exec instance-manager.sh create mysite2 57 74 apache

# Start instance
wp-dind exec instance-manager.sh start mysite

# Get access URL and configuration details
wp-dind exec instance-manager.sh info mysite
```

## Access Your Site

Open the URL shown in the instance info (e.g., http://localhost:8001)

## Common Commands

```bash
# List all instances (shows MySQL version, PHP version, web server)
wp-dind exec instance-manager.sh list

# Get detailed instance information
wp-dind exec instance-manager.sh info mysite

# Stop instance
wp-dind exec instance-manager.sh stop mysite

# View logs (all services)
wp-dind exec instance-manager.sh logs mysite

# View specific service logs
wp-dind exec instance-manager.sh logs mysite php
wp-dind exec instance-manager.sh logs mysite mysql
wp-dind exec instance-manager.sh logs mysite nginx

# Remove instance
wp-dind exec instance-manager.sh remove mysite

# Stop environment
wp-dind stop
```

## Customizing Instance Configuration

After creating an instance, you can customize its version-specific configuration:

```bash
# Edit PHP configuration (version-specific folder)
wp-dind exec vi /wordpress-instances/mysite/config/php-8.3/php.ini

# Edit MySQL configuration (version-specific folder)
wp-dind exec vi /wordpress-instances/mysite/config/mysql-8.0/my.cnf

# Edit Nginx configuration (version-specific folder)
wp-dind exec vi /wordpress-instances/mysite/config/nginx-1.27/wordpress.conf

# Or for Apache instances
wp-dind exec vi /wordpress-instances/mysite/config/apache-2.4/wordpress.conf

# Restart instance to apply changes
wp-dind exec instance-manager.sh stop mysite
wp-dind exec instance-manager.sh start mysite
```

**Note**: Config folder names include the version (e.g., `php-7.4`, `mysql-5.7`) based on what you selected when creating the instance.

## Access Services

- **WordPress**: http://localhost:8001 (or port shown in instance info)
- **phpMyAdmin**: http://localhost:8080
- **MailCatcher**: http://localhost:1080

## Next Steps

- Read [Installation Guide](INSTALLATION.md) for detailed setup
- Learn about [Architecture](ARCHITECTURE.md)
- Explore [Network Configuration](NETWORK.md)
- Review [Troubleshooting](TROUBLESHOOTING.md)

## Need Help?

Check the [Troubleshooting Guide](TROUBLESHOOTING.md) or contact aur3l.roman@gmail.com

