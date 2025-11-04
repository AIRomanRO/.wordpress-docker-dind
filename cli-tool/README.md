# WordPress Docker-in-Docker CLI Tool

A global command-line tool for managing WordPress Docker-in-Docker environments anywhere on your system.

## Installation

### Global Installation

```bash
cd cli-tool
npm install -g .
```

Or install directly from npm (once published):

```bash
npm install -g wp-dind-cli
```

### Verify Installation

```bash
wp-dind --version
```

## Quick Start

1. **Initialize a new WordPress DinD environment:**

```bash
mkdir my-wordpress-project
cd my-wordpress-project
wp-dind init
```

2. **Start the environment:**

```bash
wp-dind start
```

3. **Create a WordPress instance:**

```bash
wp-dind instance create mysite 80 83 nginx
# Or use the full command:
wp-dind exec dind instance-manager.sh create mysite 80 83 nginx
```

4. **List containers:**

```bash
wp-dind ps
```

5. **Execute commands in containers:**

```bash
# WP-CLI in PHP container
wp-dind exec mysite-php wp --info

# Access MySQL
wp-dind exec -i mysite-mysql bash
```

## Commands

### `wp-dind init`

Initialize a WordPress DinD environment in the current directory.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)
- `--with-phpmyadmin` - Include phpMyAdmin service
- `--with-mailcatcher` - Include MailCatcher service

**Example:**
```bash
wp-dind init --with-phpmyadmin --with-mailcatcher
```

### `wp-dind start`

Start the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind start
```

### `wp-dind stop`

Stop the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind stop
```

### `wp-dind status`

Check the status of the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind status
```

### `wp-dind logs`

View logs from the WordPress DinD environment.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)
- `-f, --follow` - Follow log output
- `-s, --service <service>` - Show logs for specific service

**Example:**
```bash
wp-dind logs -f
wp-dind logs -s wordpress-dind
```

### `wp-dind exec <container> <command>`

Execute a command inside a specific Docker container.

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)
- `-i, --interactive` - Run in interactive mode (allocate TTY)
- `-u, --user <user>` - Run as specific user (e.g., www-data, root)

**Container Names:**
- `dind` or `host` - DinD host container
- `<instance-name>-php` - PHP container
- `<instance-name>-mysql` - MySQL container
- `<instance-name>-nginx` - Nginx container
- `<instance-name>-apache` - Apache container

**Examples:**
```bash
# Execute in DinD host
wp-dind exec dind instance-manager.sh list
wp-dind exec dind docker ps
wp-dind exec -i dind bash

# Execute in WordPress instance containers
wp-dind exec mysite-php wp --info
wp-dind exec mysite-php wp plugin list
wp-dind exec mysite-php wp user list
wp-dind exec -u www-data mysite-php wp cache flush

# Access container shells
wp-dind exec -i mysite-php bash
wp-dind exec -i mysite-mysql bash
wp-dind exec -i mysite-nginx sh

# MySQL operations
wp-dind exec mysite-mysql mysql -u wordpress -p
wp-dind exec mysite-php wp db export /var/www/html/backup.sql

# Check logs
wp-dind exec mysite-nginx cat /var/log/nginx/access.log
wp-dind exec mysite-php cat /var/log/php/error.log
```

### `wp-dind instance <action> [args...]`

Convenient wrapper for WordPress instance management.

**Actions:**
- `create <name> [mysql] [php] [webserver]` - Create new instance
- `start <name>` - Start instance
- `stop <name>` - Stop instance
- `remove <name>` - Remove instance
- `list` - List all instances
- `info <name>` - Show instance information
- `logs <name> [service]` - View instance logs

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Examples:**
```bash
# Create instance (MySQL 8.0, PHP 8.3, Nginx)
wp-dind instance create mysite 80 83 nginx

# Create instance (MySQL 5.7, PHP 7.4, Apache)
wp-dind instance create oldsite 57 74 apache

# List all instances
wp-dind instance list

# Get instance info
wp-dind instance info mysite

# View logs
wp-dind instance logs mysite
wp-dind instance logs mysite php

# Start/stop instance
wp-dind instance start mysite
wp-dind instance stop mysite

# Remove instance
wp-dind instance remove mysite
```

### `wp-dind ps`

List all containers (DinD host and WordPress instances).

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)
- `-a, --all` - Show all containers (including stopped)

**Example:**
```bash
wp-dind ps
wp-dind ps -a
```

### `wp-dind destroy`

Destroy the WordPress DinD environment (removes all data).

**Options:**
- `-d, --dir <directory>` - Target directory (default: current directory)

**Example:**
```bash
wp-dind destroy
```

## WordPress Instance Management

WordPress instances can be managed using either the `wp-dind instance` command or by directly calling `instance-manager.sh`:

### Instance Parameters

- **name**: Instance name (required)
- **mysql_version**: MySQL version - 56, 57, 80 (default: 80)
- **php_version**: PHP version - 74, 80, 81, 82, 83 (default: 83)
- **webserver**: Web server - nginx, apache (default: nginx)

### Create Instance

```bash
# Using instance command (recommended)
wp-dind instance create <name> [mysql] [php] [webserver]

# Using direct exec
wp-dind exec dind instance-manager.sh create <name> [mysql] [php] [webserver]
```

**Examples:**
```bash
# MySQL 8.0, PHP 8.3, Nginx (defaults)
wp-dind instance create mysite

# MySQL 8.0, PHP 8.3, Nginx (explicit)
wp-dind instance create mysite 80 83 nginx

# MySQL 5.7, PHP 7.4, Apache
wp-dind instance create oldsite 57 74 apache

# MySQL 8.0, PHP 8.1, Nginx
wp-dind instance create testsite 80 81 nginx
```

### Manage Instances

```bash
# Start instance
wp-dind instance start <name>

# Stop instance
wp-dind instance stop <name>

# List all instances
wp-dind instance list

# Get instance info (shows credentials, URLs, status)
wp-dind instance info <name>

# View logs
wp-dind instance logs <name>           # All logs
wp-dind instance logs <name> php       # PHP logs only
wp-dind instance logs <name> mysql     # MySQL logs only
wp-dind instance logs <name> nginx     # Nginx logs only

# Remove instance
wp-dind instance remove <name>
```

## Use Cases

### Multiple Projects

You can initialize WordPress DinD environments in different directories:

```bash
# Project 1
mkdir ~/projects/client-a
cd ~/projects/client-a
wp-dind init
wp-dind start

# Project 2
mkdir ~/projects/client-b
cd ~/projects/client-b
wp-dind init
wp-dind start
```

### Remote Management

Manage environments from any directory:

```bash
wp-dind start -d ~/projects/client-a
wp-dind status -d ~/projects/client-b
```

### Development Workflow

```bash
# Initialize environment
wp-dind init --with-phpmyadmin --with-mailcatcher

# Start environment
wp-dind start

# Create development instance (MySQL 8.0, PHP 8.3, Nginx)
wp-dind instance create dev 80 83 nginx

# List all containers
wp-dind ps

# Get instance info (shows URL, credentials, etc.)
wp-dind instance info dev

# Install WordPress
wp-dind exec dev-php wp core install \
  --url=http://localhost:8000 \
  --title="Dev Site" \
  --admin_user=admin \
  --admin_password=password \
  --admin_email=admin@example.com

# Install plugins
wp-dind exec dev-php wp plugin install woocommerce --activate
wp-dind exec dev-php wp plugin install redis-cache --activate

# View logs
wp-dind instance logs dev
wp-dind logs -f

# Access container shell
wp-dind exec -i dev-php bash

# When done
wp-dind stop
```

### Working with Multiple Instances

```bash
# Create multiple instances with different configurations
wp-dind instance create prod 80 83 nginx
wp-dind instance create staging 80 82 nginx
wp-dind instance create legacy 57 74 apache

# List all instances
wp-dind instance list

# Work with specific instances
wp-dind exec prod-php wp plugin update --all
wp-dind exec staging-php wp db export /var/www/html/backup.sql
wp-dind exec legacy-php wp --info

# View specific instance logs
wp-dind instance logs prod php
wp-dind instance logs staging mysql
```

## Configuration

The CLI tool stores configuration in `~/.wp-dind-config.json`:

```json
{
  "defaultImagePath": null,
  "instances": {
    "/path/to/project": {
      "created": "2025-11-03T10:00:00.000Z",
      "services": {
        "phpmyadmin": true,
        "mailcatcher": true
      }
    }
  }
}
```

## Command Summary

| Command | Description |
|---------|-------------|
| `wp-dind init` | Initialize new environment |
| `wp-dind start` | Start environment |
| `wp-dind stop` | Stop environment |
| `wp-dind status` | Check status |
| `wp-dind ps [-a]` | List containers |
| `wp-dind logs [-f] [-s service]` | View logs |
| `wp-dind exec <container> <cmd>` | Execute command in container |
| `wp-dind instance create <name> [mysql] [php] [web]` | Create instance |
| `wp-dind instance list` | List instances |
| `wp-dind instance info <name>` | Show instance info |
| `wp-dind instance logs <name> [service]` | View instance logs |
| `wp-dind instance start/stop <name>` | Start/stop instance |
| `wp-dind instance remove <name>` | Remove instance |
| `wp-dind destroy` | Destroy environment |

## Requirements

- Node.js >= 24.0.0
- npm >= 10.0.0
- Docker
- docker-compose

## Troubleshooting

### Command not found

If `wp-dind` command is not found after installation:

1. Check if npm global bin directory is in your PATH:
   ```bash
   npm config get prefix
   ```

2. Add to your PATH (add to ~/.bashrc or ~/.zshrc):
   ```bash
   export PATH="$(npm config get prefix)/bin:$PATH"
   ```

### Docker daemon not running

Ensure Docker is running:
```bash
docker info
```

### Permission denied

On Linux, you may need to add your user to the docker group:
```bash
sudo usermod -aG docker $USER
```

Then log out and back in.

## License

MIT

