# WordPress Docker-in-Docker (DinD) Environment

A comprehensive Docker-in-Docker setup for hosting multiple WordPress instances with network isolation, image sharing, and easy management through a global CLI tool.

---

## ⚠️ DEVELOPMENT ENVIRONMENT ONLY

**This setup is designed for DEVELOPMENT and TESTING purposes only. DO NOT use in production environments.**

**Why not for production?**
- Docker-in-Docker runs in privileged mode (security risk)
- No SSL/TLS encryption configured by default
- Default credentials are weak (must be changed)
- No backup/disaster recovery mechanisms
- No high-availability or load balancing
- Optimized for ease of development, not security or performance
- Shared resources between instances (not isolated for production workloads)

**For production WordPress hosting**, use:
- Managed WordPress hosting services (WP Engine, Kinsta, etc.)
- Traditional Docker Compose with proper security hardening
- Kubernetes with WordPress Helm charts
- Dedicated VPS/servers with proper security configurations

---

## 🚀 Features

- **Docker-in-Docker Architecture**: Run multiple isolated WordPress environments within a single Docker container
- **Centralized Configuration**: All settings managed through `.env` file - ports, defaults, WordPress settings
- **Image Sharing**: Share Docker images between host and DinD container for efficient resource usage
- **Network Isolation**: Each WordPress instance runs in its own isolated network with unique IP addresses
- **Multiple PHP Versions**: Support for PHP 7.4, 8.0, 8.1, 8.2, and 8.3
- **Multiple MySQL Versions**: Support for MySQL 5.6, 5.7, and 8.0
- **Web Server Choice**: Choose between Nginx or Apache for each instance
- **Global CLI Tool**: Manage WordPress DinD environments from anywhere on your system
- **Integrated Services** (running inside DinD):
    - phpMyAdmin for database management (port 8080)
    - MailCatcher for email testing (ports 1080/1025)
    - Redis for caching and session storage (port 6379)
    - Redis Commander for Redis management (port 8082)
- **Flexible Configuration**: Three-layer config system (built-in → host → instance-specific)
- **Organized Data Structure**: Clean separation of data, config, and logs per instance
- **Version-Tagged Images**: All images use specific version tags for reproducibility

## 📋 Requirements

- Docker Engine 20.10 or higher
- docker-compose 1.29 or higher
- Node.js 24.0 or higher (for CLI tool and npm scripts)
- npm 10.0 or higher
- Linux/macOS/Windows with WSL2

## 🎯 Quick Start

### Option A: Using NPM Scripts (Recommended)

```bash
# 1. Create .env file from template
npm run init:env

# 2. Edit .env with your settings (optional)
nano .env

# 3. Build images and install CLI tool (one command!)
npm run setup

# 4. Start the DinD environment
npm start

# 5. Verify CLI is installed
npm run test:cli
```

**Available npm scripts:**
- `npm run setup` - Build images + install CLI (complete setup)
- `npm start` - Start DinD container
- `npm stop` - Stop DinD container
- `npm run logs` - View container logs
- `npm run status` - Check container status
- `npm run rebuild` - Rebuild images and restart

See `package.json` for all available scripts.

### Option B: Manual Setup

### 1. Configure Environment Variables (Optional)

Customize your setup by editing the `.env` file:

```bash
# Create .env from template
cp .env.example .env

# Edit .env to customize:
# - Ports (phpMyAdmin, MailCatcher, WordPress instances)
# - Default versions (PHP, MySQL, web server)
# - WordPress installation defaults (admin user, password, email)
# - Network configuration

# Example customizations:
PHPMYADMIN_PORT=8080
DEFAULT_PHP_VERSION=83
DEFAULT_MYSQL_VERSION=80
WORDPRESS_ADMIN_USER="admin"
WORDPRESS_ADMIN_EMAIL="your-email@example.com"
```

See [Configuration Guide](docs/CONFIGURATION.md) for all available options.

### 2. Build Docker Images

Build all the required Docker images with proper version tags:

```bash
chmod +x build-images.sh
./build-images.sh
```

This will build:
- MySQL 5.6.51, 5.7.44, 8.0.40
- PHP-FPM 7.4, 8.0, 8.1, 8.2, 8.3
- Nginx 1.27
- Apache 2.4
- phpMyAdmin 5.2.3
- MailCatcher 0.10.0
- Docker-in-Docker 27.0

### 3. Install Global CLI Tool

```bash
cd cli-tool
npm install -g .
```

### 4. Initialize a WordPress Environment

```bash
mkdir my-wordpress-project
cd my-wordpress-project
wp-dind init
```

### 5. Start the Environment

```bash
wp-dind start
```

### 5. Create a WordPress Instance

Instances will use the defaults from your `.env` file unless you specify otherwise:

Create an instance with custom configuration:

```bash
# Syntax: create <name> [mysql_version] [php_version] [webserver]
# MySQL versions: 56, 57, 80 (default: 80)
# PHP versions: 74, 80, 81, 82, 83 (default: 83)
# Web servers: nginx, apache (default: nginx)

# Example 1: Default (MySQL 8.0, PHP 8.3, Nginx)
wp-dind exec instance-manager.sh create mysite

# Example 2: Custom configuration
wp-dind exec instance-manager.sh create mysite2 57 74 apache

# Start the instance
wp-dind exec instance-manager.sh start mysite
```

### 6. Access Your WordPress Site

Get the access URL:
```bash
wp-dind exec instance-manager.sh info mysite
```

## 📚 Documentation

### Getting Started
- [Quick Start Guide](docs/QUICKSTART.md) - Get up and running quickly
- [Installation Guide](docs/INSTALLATION.md) - Detailed installation instructions
- [Configuration Guide](docs/CONFIGURATION.md) - **Environment variables and configuration options**

### Usage & Reference
- [Usage Guide](docs/USAGE.md) - Comprehensive usage examples
- [Quick Reference](docs/QUICK_REFERENCE.md) - Command quick reference
- [CLI Tool Reference](cli-tool/README.md) - Global CLI tool documentation

### Technical Details
- [Architecture Overview](docs/ARCHITECTURE.md) - System architecture and design
- [Network Configuration](docs/NETWORK.md) - Network isolation and configuration
- [Image Management](docs/IMAGES.md) - Docker image details

### Help
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## 🏗️ Architecture

### Docker-in-Docker Setup

The environment uses a privileged Docker container that runs its own Docker daemon. This allows:

1. **Isolation**: Each WordPress instance runs in complete isolation
2. **Network Segmentation**: Instances can communicate or be completely isolated
3. **Resource Management**: Better control over resource allocation
4. **Image Sharing**: Efficient sharing of base images between host and DinD

### Network Architecture

```
Host System
├── Docker Daemon
    └── DinD Container (172.19.0.0/16)
        ├── Docker Daemon
        ├── Shared Network (172.21.0.0/16)
        ├── phpMyAdmin (port 8080)
        ├── MailCatcher (ports 1080/1025)
        └── WordPress Instances
            ├── Instance 1 (172.20.1.0/24)
            │   ├── MySQL
            │   ├── PHP-FPM
            │   └── Nginx/Apache
            ├── Instance 2 (172.20.2.0/24)
            │   ├── MySQL
            │   ├── PHP-FPM
            │   └── Nginx/Apache
            └── Instance N (172.20.N.0/24)
```

### Image Tagging Strategy

All images follow a consistent tagging strategy:

| Image | Version Tags | Latest |
|-------|-------------|--------|
| MySQL 5.6 | 5.6.51, 56, 5.6 | - |
| MySQL 5.7 | 5.7.44, 57, 5.7 | - |
| MySQL 8.0 | 8.0.40, 80, 8.0, 8 | ✓ |
| PHP 7.4 | 7.4, 74 | - |
| PHP 8.0 | 8.0, 80 | - |
| PHP 8.1 | 8.1, 81 | - |
| PHP 8.2 | 8.2, 82 | - |
| PHP 8.3 | 8.3, 83 | ✓ |
| Nginx | 1.27, 1.27-alpine | ✓ |
| Apache | 2.4, 2.4-alpine | ✓ |
| phpMyAdmin | 5.2.3 | ✓ |
| MailCatcher | 0.10.0 | ✓ |
| DinD | 27.0, 27 | ✓ |

## 🔧 CLI Tool Commands

### Environment Management

```bash
# Initialize new environment
wp-dind init [--with-phpmyadmin] [--with-mailcatcher]

# Start environment
wp-dind start [-d <directory>]

# Stop environment
wp-dind stop [-d <directory>]

# Check status
wp-dind status [-d <directory>]

# View logs
wp-dind logs [-f] [-s <service>]

# Destroy environment
wp-dind destroy [-d <directory>]
```

### WordPress Instance Management

```bash
# Create instance with custom configuration
# Syntax: create <name> [mysql_version] [php_version] [webserver]
wp-dind exec instance-manager.sh create <name> [56|57|80] [74|80|81|82|83] [nginx|apache]

# Examples:
wp-dind exec instance-manager.sh create mysite              # Default: MySQL 8.0, PHP 8.3, Nginx
wp-dind exec instance-manager.sh create mysite2 57 74 apache  # MySQL 5.7, PHP 7.4, Apache

# Start instance
wp-dind exec instance-manager.sh start <name>

# Stop instance
wp-dind exec instance-manager.sh stop <name>

# List instances
wp-dind exec instance-manager.sh list

# Get instance info (shows config paths, data paths, credentials)
wp-dind exec instance-manager.sh info <name>

# View logs
wp-dind exec instance-manager.sh logs <name> [php|mysql|nginx|apache]

# Remove instance
wp-dind exec instance-manager.sh remove <name>
```

## 📁 Project Structure

```
wordpress-docker-dind/
├── images/                          # Docker images
│   ├── MySQL/
│   │   ├── 56/                     # MySQL 5.6.51
│   │   ├── 57/                     # MySQL 5.7.44
│   │   └── 80/                     # MySQL 8.0.40
│   ├── php/                        # PHP-FPM images
│   │   ├── 7.4/                    # PHP 7.4
│   │   ├── 8.0/                    # PHP 8.0
│   │   ├── 8.1/                    # PHP 8.1
│   │   ├── 8.2/                    # PHP 8.2
│   │   └── 8.3/                    # PHP 8.3
│   ├── nginx/                      # Nginx 1.27
│   ├── apache/                     # Apache 2.4
│   ├── phpMyAdmin/                 # phpMyAdmin 5.2.3
│   ├── mailCatcher/                # MailCatcher 0.10.0
│   └── docker-dind-wp/             # DinD base image
│       ├── Dockerfile
│       ├── entrypoint.sh
│       ├── supervisord.conf
│       ├── nginx-phpmyadmin.conf
│       ├── phpmyadmin-config.inc.php
│       ├── network-setup.sh
│       └── instance-manager.sh
├── cli-tool/                        # Global CLI tool
│   ├── bin/
│   │   └── wp-dind.js
│   ├── package.json
│   └── README.md
├── docs/                            # Documentation
├── docker-compose-dind.yml          # DinD compose file
├── build-images.sh                  # Image build script
└── README.md
```

### Instance Directory Structure

Each WordPress instance has the following structure with version-specific config and log folders:

```
/wordpress-instances/<instance-name>/
├── config/                          # Version-specific configuration files
│   ├── php-8.3/                    # PHP version-specific config (e.g., php-7.4, php-8.0, etc.)
│   │   └── php.ini                 # Custom PHP settings
│   ├── mysql-8.0/                  # MySQL version-specific config (e.g., mysql-5.6, mysql-5.7, etc.)
│   │   └── my.cnf                  # Custom MySQL settings
│   └── nginx-1.27/                 # or apache-2.4/ - Web server version-specific config
│       └── wordpress.conf          # Web server configuration
├── data/                            # Persistent data
│   ├── wordpress/                  # WordPress files (wp-content, etc.)
│   ├── mysql/                      # MySQL database files
│   └── logs/                       # Version-specific application logs
│       ├── php-8.3/                # PHP version-specific logs (e.g., php-7.4, php-8.0, etc.)
│       ├── mysql-8.0/              # MySQL version-specific logs (e.g., mysql-5.6, mysql-5.7, etc.)
│       └── nginx-1.27/             # or apache-2.4/ - Web server version-specific logs
├── docker-compose.yml               # Instance compose file
└── .instance-info                   # Instance metadata
```

**Note**: Both config and log folders are named with the image version (e.g., `php-7.4`, `mysql-5.7`, `nginx-1.27`, `apache-2.4`) allowing different instances to use different versions with their own isolated configurations and logs.

## 🌐 Integrated Services

All services run inside the DinD container for better isolation and resource management.

### phpMyAdmin
- **URL**: http://localhost:8080
- **Purpose**: Database management for all WordPress instances
- **Version**: 5.2.3
- **Location**: Runs inside DinD container
- **Access**: Can connect to any MySQL instance in the DinD environment

### MailCatcher
- **Web UI**: http://localhost:1080
- **SMTP**: localhost:1025
- **Purpose**: Email testing and debugging
- **Version**: 0.10.0

### Redis
- **Port**: localhost:6379
- **Purpose**: Caching and session storage for WordPress instances
- **Version**: 7.4
- **Location**: Runs inside DinD container
- **Configuration**: 256MB max memory, LRU eviction policy
- **Persistence**: RDB snapshots + AOF (Append Only File)

### Redis Commander
- **Web UI**: http://localhost:8082
- **Purpose**: Visual interface for managing and viewing Redis data
- **Version**: Latest
- **Credentials**: admin / admin
- **Features**: Browse keys, view values, execute commands, monitor stats

## 🔐 Security Considerations

1. **Privileged Container**: The DinD container runs in privileged mode - use only in development
2. **Network Isolation**: Each instance has its own isolated network
3. **Database Credentials**: Auto-generated strong passwords for each instance
4. **Port Exposure**: Only necessary ports are exposed to the host

## 🚀 Advanced Usage

### Customizing Instance Configuration

Each instance has its own configuration files that can be customized:

#### PHP Configuration

Edit `<instance-dir>/config/php/php.ini`:

```ini
memory_limit = 512M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 600
```

After editing, restart the instance:
```bash
wp-dind exec instance-manager.sh stop mysite
wp-dind exec instance-manager.sh start mysite
```

#### MySQL Configuration

Edit `<instance-dir>/config/mysql/my.cnf`:

```ini
[mysqld]
max_connections = 200
innodb_buffer_pool_size = 512M
```

#### Web Server Configuration

For Nginx, edit `<instance-dir>/config/nginx/wordpress.conf`:

```nginx
client_max_body_size 128M;
```

For Apache, edit `<instance-dir>/config/apache/wordpress.conf`:

```apache
LimitRequestBody 134217728
```

### Sharing Images with Host

Place Docker image tarballs in the `shared-images/` directory:

```bash
# Export image from host
docker save wordpress:latest -o shared-images/wordpress-latest.tar

# Images will be automatically loaded when DinD starts
```

### Custom Network Configuration

Edit `docker-compose-dind.yml` to customize network ranges:

```yaml
environment:
  ENABLE_NETWORK_ISOLATION: "true"
```

### Multiple Environments

Run multiple DinD environments on the same host:

```bash
# Project A
mkdir ~/projects/client-a && cd ~/projects/client-a
wp-dind init
wp-dind start

# Project B
mkdir ~/projects/client-b && cd ~/projects/client-b
wp-dind init
wp-dind start
```

## 🐛 Troubleshooting

### DinD Container Won't Start

```bash
# Check Docker daemon
docker info

# Check logs
wp-dind logs -f wordpress-dind
```

### Instance Creation Fails

```bash
# Check available networks
wp-dind exec docker network ls

# Check Docker daemon inside DinD
wp-dind exec docker info
```

### Port Conflicts

Modify port mappings in `docker-compose.yml`:

```yaml
ports:
  - "8080:80"  # Change 8080 to another port
```

## 📝 License

MIT License - see LICENSE file for details

## 👤 Author

**Aurel Roman**
- Email: aur3l.roman@gmail.com

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

## ⭐ Show Your Support

Give a ⭐️ if this project helped you!

