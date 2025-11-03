# Docker Image Management Guide

This document covers the Docker images used in the WordPress DinD environment, including version management, building, tagging, and sharing strategies.

## Image Inventory

### Custom Images

| Image Name | Base Image | Version | Tags | Purpose |
|------------|-----------|---------|------|---------|
| wp-mysql | mysql:5.6.51 | 5.6.51 | 5.6.51, 56, 5.6 | MySQL 5.6 database |
| wp-mysql | mysql:5.7.44 | 5.7.44 | 5.7.44, 57, 5.7 | MySQL 5.7 database |
| wp-mysql | mysql:8.0.40 | 8.0.40 | 8.0.40, 80, 8.0, 8, latest | MySQL 8.0 database |
| wp-php | php:7.4-fpm-alpine | 7.4 | 7.4, 74 | PHP-FPM 7.4 |
| wp-php | php:8.0-fpm-alpine | 8.0 | 8.0, 80 | PHP-FPM 8.0 |
| wp-php | php:8.1-fpm-alpine | 8.1 | 8.1, 81 | PHP-FPM 8.1 |
| wp-php | php:8.2-fpm-alpine | 8.2 | 8.2, 82 | PHP-FPM 8.2 |
| wp-php | php:8.3-fpm-alpine | 8.3 | 8.3, 83, latest | PHP-FPM 8.3 |
| wp-nginx | nginx:1.27-alpine | 1.27 | 1.27, 1.27-alpine, latest | Nginx web server |
| wp-apache | httpd:2.4-alpine | 2.4 | 2.4, 2.4-alpine, latest | Apache web server |
| wp-phpmyadmin | phpmyadmin:5.2.3 | 5.2.3 | 5.2.3, latest | Database management |
| wp-mailcatcher | alpine:3.20 | 0.10.0 | 0.10.0, latest | Email testing |
| wp-dind | docker:27-dind | 27.0 | 27.0, 27, latest | Docker-in-Docker |


## Image Specifications

### PHP-FPM Images

All PHP images are based on official PHP-FPM Alpine images and include:

**Installed Extensions:**
- Core: bcmath, exif, gd, intl, ldap, mbstring, mysqli, opcache, pdo, pdo_mysql, pdo_pgsql, pdo_sqlite, soap, zip
- PECL: imagick, redis
- Graphics: GD with FreeType, JPEG, WebP support

**Additional Tools:**
- Composer (latest)
- WP-CLI ready

**Configuration:**
- Memory limit: 256M (customizable per instance)
- Upload max filesize: 64M (customizable per instance)
- Post max size: 64M (customizable per instance)
- Max execution time: 300s (customizable per instance)
- OPcache enabled with WordPress-optimized settings

**Version Support:**
- PHP 7.4: Legacy support for older WordPress sites
- PHP 8.0: Stable version with good plugin compatibility
- PHP 8.1: Recommended for most WordPress sites
- PHP 8.2: Latest stable with performance improvements
- PHP 8.3: Cutting edge, best performance (default)

### Apache Image

Based on official Apache 2.4 Alpine image with:

**Enabled Modules:**
- mod_rewrite (for WordPress permalinks)
- mod_proxy and mod_proxy_fcgi (for PHP-FPM)
- mod_headers (for security headers)
- mod_expires (for caching)
- mod_deflate (for compression)
- mod_ssl (for HTTPS support)

**Configuration:**
- AllowOverride All (for .htaccess support)
- DirectoryIndex includes index.php
- Custom site configurations in /etc/apache2/conf.d/

### Nginx Image

Based on official Nginx 1.27 Alpine image with:

**Features:**
- FastCGI support for PHP-FPM
- Gzip compression enabled
- Client max body size: 64M (customizable)
- Custom site configurations in /etc/nginx/conf.d/

**Optimizations:**
- Worker processes: auto
- Keepalive timeout: 65s
- Client body buffer size: 128k


## Image Tagging Strategy

### Semantic Versioning

All custom images follow semantic versioning (semver):

**Format**: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes, incompatible API changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes, backwards compatible

### Tag Hierarchy

Each image has multiple tags for flexibility:

1. **Full Version Tag** (e.g., `wp-mysql:8.0.40`)
   - Most specific
   - Recommended for production
   - Ensures exact version

2. **Major.Minor Tag** (e.g., `wp-mysql:8.0`)
   - Allows patch updates
   - Good balance for production
   - Receives security updates

3. **Major Version Tag** (e.g., `wp-mysql:8`)
   - Allows minor and patch updates
   - More flexible
   - May include breaking changes

4. **Short Version Tag** (e.g., `wp-mysql:80`)
   - Convenience tag
   - Same as major.minor
   - Easier to type

5. **Latest Tag** (e.g., `wp-mysql:latest`)
   - Points to newest version
   - Good for development
   - Not recommended for production

### Example Tag Usage

```bash
# Production - use full version
docker pull wp-mysql:8.0.40

# Staging - use major.minor
docker pull wp-mysql:8.0

# Development - use latest
docker pull wp-mysql:latest
```

## Building Images

### Build All Images

Use the provided build script:

```bash
chmod +x build-images.sh
./build-images.sh
```

### Build Individual Images

#### MySQL Images

```bash
# MySQL 5.6
docker build -t wp-mysql:5.6.51 ./images/MySQL/56
docker tag wp-mysql:5.6.51 wp-mysql:56
docker tag wp-mysql:5.6.51 wp-mysql:5.6

# MySQL 5.7
docker build -t wp-mysql:5.7.44 ./images/MySQL/57
docker tag wp-mysql:5.7.44 wp-mysql:57
docker tag wp-mysql:5.7.44 wp-mysql:5.7

# MySQL 8.0
docker build -t wp-mysql:8.0.40 ./images/MySQL/80
docker tag wp-mysql:8.0.40 wp-mysql:80
docker tag wp-mysql:8.0.40 wp-mysql:8.0
docker tag wp-mysql:8.0.40 wp-mysql:8
docker tag wp-mysql:8.0.40 wp-mysql:latest
```

#### PHP-FPM Images

```bash
# PHP 7.4
docker build -t wp-php:7.4 ./images/php/7.4
docker tag wp-php:7.4 wp-php:74

# PHP 8.0
docker build -t wp-php:8.0 ./images/php/8.0
docker tag wp-php:8.0 wp-php:80

# PHP 8.1
docker build -t wp-php:8.1 ./images/php/8.1
docker tag wp-php:8.1 wp-php:81

# PHP 8.2
docker build -t wp-php:8.2 ./images/php/8.2
docker tag wp-php:8.2 wp-php:82

# PHP 8.3
docker build -t wp-php:8.3 ./images/php/8.3
docker tag wp-php:8.3 wp-php:83
docker tag wp-php:8.3 wp-php:latest
```

#### Nginx Image

```bash
docker build -t wp-nginx:1.27 ./images/nginx
docker tag wp-nginx:1.27 wp-nginx:1.27-alpine
docker tag wp-nginx:1.27 wp-nginx:latest
```

#### Apache Image

```bash
docker build -t wp-apache:2.4 ./images/apache
docker tag wp-apache:2.4 wp-apache:2.4-alpine
docker tag wp-apache:2.4 wp-apache:latest
```

#### phpMyAdmin Image

```bash
docker build -t wp-phpmyadmin:5.2.3 ./images/phpMyAdmin
docker tag wp-phpmyadmin:5.2.3 wp-phpmyadmin:latest
```

#### MailCatcher Image

```bash
docker build -t wp-mailcatcher:0.10.0 ./images/mailCatcher
docker tag wp-mailcatcher:0.10.0 wp-mailcatcher:latest
```

#### Docker-in-Docker Image

```bash
docker build -t wp-dind:27.0 ./images/docker-dind-wp
docker tag wp-dind:27.0 wp-dind:27
docker tag wp-dind:27.0 wp-dind:latest
```

## Image Sharing

### Host to DinD Container

#### Method 1: Volume Mount (Recommended)

1. **Export images from host**:
```bash
# Create shared-images directory
mkdir -p shared-images

# Export images
docker save wordpress:latest -o shared-images/wordpress-latest.tar
docker save wordpress:php8.3 -o shared-images/wordpress-php83.tar
docker save wordpress:php8.2 -o shared-images/wordpress-php82.tar
```

2. **Images are automatically loaded** when DinD container starts (via entrypoint.sh)

3. **Verify images in DinD**:
```bash
wp-dind exec docker images
```

#### Method 2: Docker Registry

1. **Run a local registry**:
```bash
docker run -d -p 5000:5000 --name registry registry:2
```

2. **Tag and push images**:
```bash
docker tag wp-mysql:8.0.40 localhost:5000/wp-mysql:8.0.40
docker push localhost:5000/wp-mysql:8.0.40
```

3. **Pull from DinD**:
```bash
wp-dind exec docker pull localhost:5000/wp-mysql:8.0.40
```

#### Method 3: Docker Socket (Advanced)

Mount Docker socket (use with caution):

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker-host.sock:ro
```

Then use docker CLI to access host images.

### DinD to Host

Export images from DinD to host:

```bash
# Export from DinD
wp-dind exec docker save myimage:tag -o /shared-images/myimage.tar

# Load on host
docker load -i shared-images/myimage.tar
```

## Image Optimization

### Reduce Image Size

#### Use Multi-stage Builds

```dockerfile
# Build stage
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
```

#### Minimize Layers

```dockerfile
# Bad - multiple layers
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2

# Good - single layer
RUN apt-get update && \
    apt-get install -y package1 package2 && \
    rm -rf /var/lib/apt/lists/*
```

#### Use .dockerignore

```
# .dockerignore
node_modules
.git
.env
*.log
```

### Image Caching

#### Leverage Build Cache

```dockerfile
# Copy dependency files first
COPY package*.json ./
RUN npm install

# Copy source code last (changes more frequently)
COPY . .
```

#### Use BuildKit

```bash
# Enable BuildKit
export DOCKER_BUILDKIT=1

# Build with cache
docker build --cache-from wp-mysql:8.0 -t wp-mysql:8.0.40 .
```

## Image Maintenance

### Updating Images

#### Update Base Images

1. **Check for updates**:
```bash
docker pull mysql:8.0
docker pull nginx:alpine
docker pull phpmyadmin:latest
```

2. **Rebuild custom images**:
```bash
./build-images.sh
```

3. **Test new images**:
```bash
# Create test instance
wp-dind exec instance-manager.sh create test-new 80

# Verify functionality
wp-dind exec instance-manager.sh info test-new
```

4. **Update production instances**:
```bash
# Stop instance
wp-dind exec instance-manager.sh stop mysite

# Update docker-compose.yml to use new image version
wp-dind exec vi /wordpress-instances/mysite/docker-compose.yml

# Start instance
wp-dind exec instance-manager.sh start mysite
```

### Security Updates

#### Scan Images for Vulnerabilities

```bash
# Using Docker Scout
docker scout cves wp-mysql:8.0.40

# Using Trivy
trivy image wp-mysql:8.0.40

# Using Snyk
snyk container test wp-mysql:8.0.40
```

#### Update Vulnerable Images

```bash
# Pull latest base image
docker pull mysql:8.0

# Rebuild
docker build -t wp-mysql:8.0.40 ./images/MySQL/80

# Retag
docker tag wp-mysql:8.0.40 wp-mysql:latest
```

### Cleanup

#### Remove Unused Images

```bash
# Remove dangling images
docker image prune

# Remove all unused images
docker image prune -a

# Remove specific version
docker rmi wp-mysql:8.0.39
```

#### Cleanup Build Cache

```bash
# Remove build cache
docker builder prune

# Remove all cache
docker builder prune -a
```

## Image Registry

### Private Registry Setup

#### Run Local Registry

```bash
# Start registry
docker run -d -p 5000:5000 \
  --name registry \
  -v registry-data:/var/lib/registry \
  registry:2

# Verify
curl http://localhost:5000/v2/_catalog
```

#### Push Images to Registry

```bash
# Tag for registry
docker tag wp-mysql:8.0.40 localhost:5000/wp-mysql:8.0.40

# Push
docker push localhost:5000/wp-mysql:8.0.40

# List images in registry
curl http://localhost:5000/v2/_catalog
```

#### Pull from Registry

```bash
# From host
docker pull localhost:5000/wp-mysql:8.0.40

# From DinD
wp-dind exec docker pull localhost:5000/wp-mysql:8.0.40
```

### Cloud Registry

#### Docker Hub

```bash
# Login
docker login

# Tag
docker tag wp-mysql:8.0.40 username/wp-mysql:8.0.40

# Push
docker push username/wp-mysql:8.0.40
```

#### AWS ECR

```bash
# Login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789012.dkr.ecr.us-east-1.amazonaws.com

# Tag
docker tag wp-mysql:8.0.40 \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/wp-mysql:8.0.40

# Push
docker push \
  123456789012.dkr.ecr.us-east-1.amazonaws.com/wp-mysql:8.0.40
```

## Image Documentation

### Dockerfile Best Practices

```dockerfile
# Use specific base image version
FROM mysql:8.0.40

# Add metadata
LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="8.0.40"
LABEL description="MySQL 8.0 for WordPress Docker-in-Docker setup"

# Set environment variables
ENV MYSQL_ROOT_PASSWORD=""
ENV MYSQL_DATABASE="wordpress"

# Create necessary directories
RUN mkdir -p /var/lib/mysql /var/log/mysql

# Copy configuration files
COPY my.cnf /etc/mysql/conf.d/

# Set permissions
RUN chmod 0444 /etc/mysql/conf.d/my.cnf

# Expose ports
EXPOSE 3306

# Set working directory
WORKDIR /var/lib/mysql

# Define volumes
VOLUME ["/var/lib/mysql"]

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD mysqladmin ping -h localhost || exit 1

# Default command
CMD ["mysqld"]
```

### Image Labels

Use labels for metadata:

```dockerfile
LABEL org.opencontainers.image.created="2025-11-03"
LABEL org.opencontainers.image.authors="aur3l.roman@gmail.com"
LABEL org.opencontainers.image.url="https://github.com/yourusername/wordpress-docker-dind"
LABEL org.opencontainers.image.documentation="https://github.com/yourusername/wordpress-docker-dind/docs"
LABEL org.opencontainers.image.source="https://github.com/yourusername/wordpress-docker-dind"
LABEL org.opencontainers.image.version="8.0.40"
LABEL org.opencontainers.image.vendor="Your Organization"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="WordPress MySQL"
LABEL org.opencontainers.image.description="MySQL database for WordPress DinD"
```

## Troubleshooting

### Build Failures

```bash
# Check build logs
docker build --progress=plain -t wp-mysql:8.0.40 ./images/MySQL/80

# Build without cache
docker build --no-cache -t wp-mysql:8.0.40 ./images/MySQL/80

# Check disk space
docker system df
```

### Image Pull Failures

```bash
# Check network connectivity
ping registry.hub.docker.com

# Check Docker daemon
docker info

# Try with different registry mirror
docker pull --registry-mirror=https://mirror.gcr.io mysql:8.0
```

### Image Size Issues

```bash
# Analyze image layers
docker history wp-mysql:8.0.40

# Find large files
docker run --rm wp-mysql:8.0.40 du -sh /*

# Use dive for detailed analysis
dive wp-mysql:8.0.40
```

## References

- [Docker Image Documentation](https://docs.docker.com/engine/reference/builder/)
- [Best Practices for Writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Image Specification](https://github.com/opencontainers/image-spec)

