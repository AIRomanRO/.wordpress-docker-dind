# Changelog

## [Unreleased]

### Added

#### CI/CD
- **Automated Changelog Generation**: GitHub Action workflow that automatically updates CHANGELOG.md when PRs are merged
  - Parses Conventional Commit messages from merged PRs
  - Categorizes changes by type (feat, fix, docs, etc.)
  - Generates formatted changelog entries with PR links
  - Commits changes back to the repository
  - Posts changelog entry as PR comment
- **Conventional Commits Guide**: Comprehensive documentation for using Conventional Commits format
- **PR Template**: Pull request template with commit type checklist
- **Contributing Guide**: Complete contribution guidelines with development workflow

#### Documentation
- Added `.github/CONVENTIONAL_COMMITS.md` - Detailed guide on Conventional Commits
- Added `.github/COMMIT_TYPES.md` - Quick reference card for commit types
- Added `.github/workflows/README.md` - Documentation for GitHub Actions workflows
- Added `.github/PULL_REQUEST_TEMPLATE.md` - Template for pull requests
- Added `CONTRIBUTING.md` - Contribution guidelines and development workflow
- Updated `README.md` with contributing section and automated changelog information

---

## [2.0.0] - 2025-11-03

### Major Enhancements

This release introduces significant improvements to the WordPress Docker-in-Docker setup, including multiple PHP versions, web server choice, integrated services, and better configuration management.

### Added

#### PHP-FPM Images
- **PHP 7.4** (`wp-php:7.4`, `wp-php:74`) - Legacy support for older WordPress sites
- **PHP 8.0** (`wp-php:8.0`, `wp-php:80`) - Stable version with good plugin compatibility
- **PHP 8.1** (`wp-php:8.1`, `wp-php:81`) - Recommended for most WordPress sites
- **PHP 8.2** (`wp-php:8.2`, `wp-php:82`) - Latest stable with performance improvements
- **PHP 8.3** (`wp-php:8.3`, `wp-php:83`, `wp-php:latest`) - Cutting edge, best performance (default)

All PHP images include:
- Core extensions: bcmath, exif, gd, intl, ldap, mbstring, mysqli, opcache, pdo, pdo_mysql, pdo_pgsql, pdo_sqlite, soap, zip
- PECL extensions: imagick, redis
- Graphics: GD with FreeType, JPEG, WebP support
- Composer (latest)
- WP-CLI ready

#### Apache Web Server
- **Apache 2.4** (`wp-apache:2.4`, `wp-apache:2.4-alpine`, `wp-apache:latest`)
- Enabled modules: mod_rewrite, mod_proxy, mod_proxy_fcgi, mod_headers, mod_expires, mod_deflate, mod_ssl
- AllowOverride All for .htaccess support
- DirectoryIndex includes index.php
- Custom site configurations support

#### Integrated Services (Inside DinD Container)
- **phpMyAdmin 5.2.3** - Now runs inside DinD container on port 8080
- **MailCatcher 0.10.0** - Now runs inside DinD container on ports 1080/1025
- **Supervisor** - Process manager for all services inside DinD
- **PHP-FPM 8.3** - Serves phpMyAdmin
- **Nginx** - Serves phpMyAdmin web interface

#### Configuration Management
- **Version-specific config folders**: Each instance has config folders named with the image version
- Per-instance PHP configuration (`config/php-8.3/php.ini`, `config/php-7.4/php.ini`, etc.)
- Per-instance MySQL configuration (`config/mysql-8.0/my.cnf`, `config/mysql-5.7/my.cnf`, etc.)
- Per-instance web server configuration (`config/nginx-1.27/` or `config/apache-2.4/`)
- Default configurations created automatically on instance creation based on selected versions
- Customizable per instance
- Different instances can use different versions with their own isolated configurations

#### Log Management
- **Version-specific log folders**: Each service's logs are stored in version-specific folders
- PHP logs: `data/logs/php-8.3/`, `data/logs/php-7.4/`, etc.
- MySQL logs: `data/logs/mysql-8.0/`, `data/logs/mysql-5.7/`, etc.
- Web server logs: `data/logs/nginx-1.27/`, `data/logs/apache-2.4/`, etc.
- Easy to identify which version generated which logs
- Isolated logs per version for better debugging

#### Data Organization
New directory structure for each instance with version-specific config and log folders:
```
/wordpress-instances/<instance-name>/
├── config/                    # Version-specific configuration files
│   ├── php-8.3/              # PHP version-specific (e.g., php-7.4, php-8.0, etc.)
│   │   └── php.ini
│   ├── mysql-8.0/            # MySQL version-specific (e.g., mysql-5.6, mysql-5.7, etc.)
│   │   └── my.cnf
│   └── nginx-1.27/           # or apache-2.4/ - Web server version-specific
│       └── wordpress.conf
├── data/                      # Persistent data
│   ├── wordpress/            # WordPress files
│   ├── mysql/                # MySQL database
│   └── logs/                 # Version-specific application logs
│       ├── php-8.3/          # PHP version-specific logs
│       ├── mysql-8.0/        # MySQL version-specific logs
│       └── nginx-1.27/       # or apache-2.4/ - Web server version-specific logs
├── docker-compose.yml
└── .instance-info
```

### Changed

#### Instance Manager
- **New syntax**: `create <name> [mysql_version] [php_version] [webserver]`
- **MySQL versions**: 56, 57, 80 (default: 80)
- **PHP versions**: 74, 80, 81, 82, 83 (default: 83)
- **Web servers**: nginx, apache (default: nginx)
- **Examples**:
  - `instance-manager.sh create mysite` - Default: MySQL 8.0, PHP 8.3, Nginx
  - `instance-manager.sh create mysite2 57 74 apache` - MySQL 5.7, PHP 7.4, Apache

#### Instance Architecture
- Changed from 2-container stack (MySQL + WordPress) to 3-container stack (MySQL + PHP-FPM + Nginx/Apache)
- Separated PHP processing from web server for better performance and flexibility
- Each instance can now choose its own PHP version and web server

#### DinD Container
- Now runs multiple services managed by Supervisor
- phpMyAdmin and MailCatcher integrated inside DinD container
- Reduced number of containers on host network
- Better resource management and isolation

#### Docker Compose
- Created `docker-compose-dind.yml` for DinD setup
- Updated instance docker-compose templates to include PHP-FPM container
- Updated volume mounts to use new directory structure
- Added configuration file mounts

#### Build Script
- Added PHP-FPM image builds (5 versions)
- Added Apache image build
- Updated image summary output

### Documentation Updates

#### README.md
- Updated features list with PHP versions and web server choice
- Updated quick start guide with new instance creation syntax
- Added section on customizing instance configuration
- Updated image tagging table
- Updated architecture diagram

#### docs/IMAGES.md
- Added PHP-FPM image specifications
- Added Apache image specifications
- Updated Nginx image specifications
- Added build instructions for PHP and Apache images
- Added detailed extension lists and configuration details

#### docs/ARCHITECTURE.md
- Updated architecture diagram to show integrated services
- Updated component descriptions for 3-container stack
- Added Supervisor service management details
- Updated instance directory structure
- Added configuration management section

#### docs/QUICKSTART.md
- Updated instance creation examples
- Added configuration customization section
- Updated common commands with service-specific log viewing

### Files Created

1. `images/php/7.4/Dockerfile` - PHP 7.4-FPM image
2. `images/php/8.0/Dockerfile` - PHP 8.0-FPM image
3. `images/php/8.1/Dockerfile` - PHP 8.1-FPM image
4. `images/php/8.2/Dockerfile` - PHP 8.2-FPM image
5. `images/php/8.3/Dockerfile` - PHP 8.3-FPM image
6. `images/apache/Dockerfile` - Apache 2.4 image
7. `images/docker-dind-wp/supervisord.conf` - Supervisor configuration
8. `images/docker-dind-wp/nginx-phpmyadmin.conf` - Nginx config for phpMyAdmin
9. `images/docker-dind-wp/phpmyadmin-config.inc.php` - phpMyAdmin configuration
10. `docker-compose-dind.yml` - DinD environment compose file
11. `CHANGELOG.md` - This file

### Files Modified

1. `build-images.sh` - Added PHP and Apache image builds
2. `images/docker-dind-wp/Dockerfile` - Added integrated services
3. `images/docker-dind-wp/entrypoint.sh` - Updated to use Supervisor
4. `images/docker-dind-wp/instance-manager.sh` - Added PHP version and web server choice
5. `README.md` - Updated with new features
6. `docs/IMAGES.md` - Added PHP and Apache documentation
7. `docs/ARCHITECTURE.md` - Updated architecture details
8. `docs/QUICKSTART.md` - Updated quick start guide

### Breaking Changes

⚠️ **Important**: This release includes breaking changes to the instance creation process and directory structure.

1. **Instance Directory Structure**: Existing instances will need to be migrated to the new directory structure
2. **Instance Creation Syntax**: New parameters for PHP version and web server choice
3. **Docker Compose**: phpMyAdmin and MailCatcher are no longer separate containers on the host

### Migration Guide

For existing instances, you'll need to:

1. Stop all instances
2. Backup instance data
3. Rebuild the DinD image
4. Recreate instances with the new structure
5. Restore data to the new directory structure

### Upgrade Instructions

```bash
# 1. Stop all instances and DinD environment
wp-dind exec instance-manager.sh stop <instance-name>
wp-dind stop

# 2. Rebuild all images
./build-images.sh

# 3. Start DinD environment
wp-dind start

# 4. Create new instances with desired configuration
wp-dind exec instance-manager.sh create mysite 80 83 nginx
```

### Performance Improvements

- Separated PHP-FPM from web server for better resource utilization
- OPcache enabled by default in all PHP images
- Optimized default configurations for WordPress

### Security Improvements

- Per-instance configuration isolation
- Better log organization for security auditing
- Updated base images with latest security patches

---

## [1.0.0] - Initial Release

Initial release with basic Docker-in-Docker WordPress hosting functionality.

