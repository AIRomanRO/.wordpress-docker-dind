# WordPress Docker-in-Docker Architecture

## Overview

This document describes the architecture of the WordPress Docker-in-Docker (DinD) environment, explaining how components interact and how the system achieves isolation, scalability, and image sharing.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Host System                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    Docker Daemon                           │ │
│  │  ┌──────────────────────────────────────────────────────┐  │ │
│  │  │         DinD Container (wordpress-dind-host)         │  │ │
│  │  │  ┌────────────────────────────────────────────────┐  │  │ │
│  │  │  │          Docker Daemon (Inner)                 │  │  │ │
│  │  │  │  ┌──────────────────────────────────────────┐  │  │  │ │
│  │  │  │  ┌──────────────────────────────────────────┐  │  │  │ │
│  │  │  │  │    WordPress Instance 1                  │  │  │  │ │
│  │  │  │  │  ┌─────────┬──────────┬────────────┐     │  │  │  │ │
│  │  │  │  │  │  MySQL  │ PHP-FPM  │Nginx/Apache│     │  │  │  │ │
│  │  │  │  │  └─────────┴──────────┴────────────┘     │  │  │  │ │
│  │  │  │  │  Network: 172.20.1.0/24                  │  │  │  │ │
│  │  │  │  └──────────────────────────────────────────┘  │  │  │ │
│  │  │  │  ┌──────────────────────────────────────────┐  │  │  │ │
│  │  │  │  │    WordPress Instance 2                  │  │  │  │ │
│  │  │  │  │  ┌─────────┬──────────┬────────────┐     │  │  │  │ │
│  │  │  │  │  │  MySQL  │ PHP-FPM  │Nginx/Apache│     │  │  │  │ │
│  │  │  │  │  └─────────┴──────────┴────────────┘     │  │  │  │ │
│  │  │  │  │  Network: 172.20.2.0/24                  │  │  │  │ │
│  │  │  │  └──────────────────────────────────────────┘  │  │  │ │
│  │  │  │  ┌──────────────────────────────────────────┐  │  │  │ │
│  │  │  │  │    Shared Network (wp-shared)            │  │  │  │ │
│  │  │  │  │    172.21.0.0/16                         │  │  │  │ │
│  │  │  │  └──────────────────────────────────────────┘  │  │  │ │
│  │  │  │  ┌──────────────────────────────────────────┐  │  │  │ │
│  │  │  │  │    Integrated Services (Supervisor)      │  │  │  │ │
│  │  │  │  │  - phpMyAdmin (port 8080)                │  │  │  │ │
│  │  │  │  │  - MailCatcher (ports 1080/1025)         │  │  │  │ │
│  │  │  │  │  - PHP-FPM 8.3 (port 9000)               │  │  │  │ │
│  │  │  │  │  - Nginx (port 8080 for phpMyAdmin)      │  │  │  │ │
│  │  │  │  └──────────────────────────────────────────┘  │  │  │ │
│  │  │  └────────────────────────────────────────────────┘  │  │ │
│  │  │  Network: 172.19.0.0/16                              │  │ │
│  │  └──────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Docker-in-Docker Container

**Image**: `wp-dind:27.0`

The DinD container is the heart of the system. It runs a Docker daemon inside a Docker container, enabling:

- **Nested containerization**: Run Docker containers within a Docker container
- **Isolation**: Complete isolation between WordPress instances
- **Resource management**: Centralized control over all WordPress instances
- **Image sharing**: Efficient sharing of Docker images

**Key Features**:
- Runs in privileged mode (required for nested Docker)
- Exposes Docker daemon on port 2375 (optional, for remote management)
- Mounts volumes for persistent data
- Includes management scripts for instance lifecycle

**Scripts**:
- `entrypoint.sh`: Initializes supervisord which manages all services
- `network-setup.sh`: Creates isolated networks for WordPress instances
- `instance-manager.sh`: Manages WordPress instance lifecycle

**Integrated Services** (managed by Supervisor):
- Docker daemon (dockerd)
- PHP-FPM 8.3 (for phpMyAdmin)
- Nginx (serves phpMyAdmin on port 8080)
- MailCatcher (web UI on 1080, SMTP on 1025)

### 2. WordPress Instances

Each WordPress instance consists of three containers:

#### MySQL Container
- **Images**: `wp-mysql:5.6.51`, `wp-mysql:5.7.44`, `wp-mysql:8.0.40`
- **Purpose**: Database server for WordPress
- **Configuration**: Custom my.cnf for optimization (per-instance customizable)
- **Data**: Persisted in `data/mysql/` directory
- **Logs**: Stored in `data/logs/mysql/` directory

#### PHP-FPM Container
- **Images**: `wp-php:7.4`, `wp-php:8.0`, `wp-php:8.1`, `wp-php:8.2`, `wp-php:8.3`
- **Purpose**: PHP processing for WordPress
- **Extensions**: All WordPress-required extensions plus imagick, redis
- **Configuration**: Custom php.ini for optimization (per-instance customizable)
- **Data**: WordPress files in `data/wordpress/` directory
- **Logs**: Stored in `data/logs/php/` directory

#### Web Server Container (Nginx or Apache)
- **Nginx Image**: `wp-nginx:1.27`
- **Apache Image**: `wp-apache:2.4`
- **Purpose**: Web server and reverse proxy to PHP-FPM
- **Configuration**: Custom config files (per-instance customizable)
- **Ports**: Dynamically assigned from host port range (8000-8099)
- **Logs**: Stored in `data/logs/nginx/` or `data/logs/apache/` directory

### 3. Integrated Services (Inside DinD Container)

All support services run inside the DinD container, managed by Supervisor for better resource management and isolation.

#### phpMyAdmin
- **Version**: 5.2.3
- **Purpose**: Web-based database management
- **Access**: http://localhost:8080
- **Features**:
  - Can connect to any MySQL instance in the DinD environment
  - Served by Nginx with PHP-FPM 8.3
  - Persistent configuration
- **Process Manager**: Supervised by supervisord

#### MailCatcher
- **Version**: 0.10.0
- **Purpose**: Email testing and debugging
- **Access**:
  - Web UI: http://localhost:1080
  - SMTP: localhost:1025
- **Features**:
  - Catches all emails sent by WordPress instances
  - Web interface for viewing emails
  - No emails are actually sent to real addresses
- **Process Manager**: Supervised by supervisord

#### PHP-FPM (for phpMyAdmin)
- **Version**: 8.3
- **Purpose**: Serves phpMyAdmin
- **Port**: 9000 (internal)
- **Process Manager**: Supervised by supervisord

#### Nginx (for phpMyAdmin)
- **Purpose**: Web server for phpMyAdmin
- **Port**: 8080
- **Configuration**: `/etc/nginx/conf.d/phpmyadmin.conf`
- **Process Manager**: Supervised by supervisord

## Network Architecture

### Network Layers

#### Layer 1: Host Network
- The host system's network
- Exposes services to the outside world

#### Layer 2: DinD Bridge Network
- **Subnet**: 172.19.0.0/16
- **Purpose**: Connects DinD container to host network
- **Services**: DinD container with integrated phpMyAdmin and MailCatcher
- **Isolation**: Isolated from WordPress instances

#### Layer 3: Shared Network (Inside DinD)
- **Subnet**: 172.21.0.0/16
- **Name**: wp-shared
- **Purpose**: Optional inter-instance communication
- **Use Case**: When instances need to communicate with each other

#### Layer 4: Instance Networks (Inside DinD)
- **Subnet Pattern**: 172.20.N.0/24 (where N is the instance ID)
- **Name Pattern**: wp-network-N
- **Purpose**: Isolated network for each WordPress instance
- **Isolation**: Complete network isolation between instances

### Network Isolation

Each WordPress instance runs in its own isolated network:

```
Instance 1: 172.20.1.0/24
├── MySQL:      172.20.1.2
├── WordPress:  172.20.1.3
└── Nginx:      172.20.1.4

Instance 2: 172.20.2.0/24
├── MySQL:      172.20.2.2
├── WordPress:  172.20.2.3
└── Nginx:      172.20.2.4
```

**Benefits**:
- Instances cannot interfere with each other
- Each instance can use the same internal port numbers
- Network-level security between instances
- Easy to implement firewall rules

### Inter-Instance Communication

If instances need to communicate, they can be connected to the shared network:

```bash
docker network connect wp-shared instance1-wordpress
docker network connect wp-shared instance2-wordpress
```

## Image Management

### Image Tagging Strategy

All custom images follow a consistent tagging strategy:

1. **Specific Version Tag**: e.g., `wp-mysql:8.0.40`
   - Pinned to exact version
   - Ensures reproducibility
   - Recommended for production

2. **Major.Minor Tag**: e.g., `wp-mysql:8.0`
   - Allows patch updates
   - Balance between stability and updates

3. **Major Version Tag**: e.g., `wp-mysql:8`
   - Allows minor and patch updates
   - More flexible, less stable

4. **Latest Tag**: e.g., `wp-mysql:latest`
   - Always points to the newest version
   - Useful for development
   - Not recommended for production

### Image Sharing

Images can be shared between host and DinD container:

#### Method 1: Volume Mount (Automatic)
```yaml
volumes:
  - ./shared-images:/shared-images
```

Place image tarballs in `shared-images/`:
```bash
docker save wordpress:latest -o shared-images/wordpress-latest.tar
```

The DinD entrypoint automatically loads these images on startup.

#### Method 2: Docker Socket (Advanced)
```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker-host.sock:ro
```

Allows direct access to host Docker daemon (use with caution).

## Data Persistence

### Volume Strategy

#### DinD Container Volumes
- `wordpress-instances`: All WordPress instance data
- `dind-docker-data`: Docker daemon data (images, containers, networks)
- `shared-images`: Shared Docker images

#### Instance Volumes (Inside DinD)
Each instance has its own directory structure with version-specific config and log folders:
```
/wordpress-instances/<instance-name>/
├── config/                         # Version-specific configuration files
│   ├── php-8.3/                   # PHP version-specific config
│   │   └── php.ini                # Custom PHP settings (can enable Xdebug here)
│   ├── mysql-8.0/                 # MySQL version-specific config
│   │   └── my.cnf                 # Custom MySQL settings
│   └── nginx-1.27/                # or apache-2.4/ - Web server version-specific config
│       └── wordpress.conf         # Web server configuration
├── data/                           # Persistent data
│   ├── wordpress/                 # WordPress files (wp-content, etc.)
│   └── mysql/                     # MySQL database files
├── logs/                           # Version-specific application logs
│   ├── php-8.3/                   # PHP version-specific logs (error.log, xdebug.log)
│   ├── mysql-8.0/                 # MySQL version-specific logs (error.log, slow-query.log)
│   └── nginx-1.27/                # or apache-2.4/ - Web server version-specific logs
├── docker-compose.yml              # Instance compose file
└── .instance-info                  # Instance metadata (MySQL version, PHP version, web server)
```

**Configuration Management:**
- Each instance has version-specific configuration folders
- Config folders are named with the image version (e.g., `php-8.3`, `mysql-8.0`, `nginx-1.27`)
- Default configurations are created automatically based on selected versions
- Configurations can be customized per instance
- Changes require instance restart to take effect
- Different instances can use different versions with their own configs

**Data Organization:**
- `data/wordpress/`: WordPress core files and wp-content
- `data/mysql/`: MySQL database files
- `logs/`: All application logs organized by service and version (separate from data)

**Version-Specific Config Examples:**
- Instance with PHP 7.4: `config/php-7.4/php.ini` → logs in `logs/php-7.4/`
- Instance with PHP 8.3: `config/php-8.3/php.ini` → logs in `logs/php-8.3/`
- Instance with MySQL 5.7: `config/mysql-5.7/my.cnf` → logs in `logs/mysql-5.7/`
- Instance with MySQL 8.0: `config/mysql-8.0/my.cnf` → logs in `logs/mysql-8.0/`
- Instance with Nginx: `config/nginx-1.27/wordpress.conf` → logs in `logs/nginx-1.27/`
- Instance with Apache: `config/apache-2.4/wordpress.conf` → logs in `logs/apache-2.4/`

**Xdebug Support:**
- Xdebug is installed in all PHP images but disabled by default
- To enable Xdebug, edit `config/php-{version}/php.ini` and set `xdebug.mode=debug`
- Xdebug logs are written to `logs/php-{version}/xdebug.log`
- Default configuration: client_host=host.docker.internal, client_port=9003, idekey=PHPSTORM

### Backup Strategy

#### Full Backup
```bash
# Backup all instances
docker run --rm \
  -v wordpress-instances:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/instances-backup.tar.gz /data
```

#### Single Instance Backup
```bash
wp-dind exec tar czf /backup/instance-name.tar.gz \
  /wordpress-instances/instance-name
```

## Security Architecture

### Isolation Levels

1. **Container Isolation**: Each service runs in its own container
2. **Network Isolation**: Each instance has its own network
3. **Filesystem Isolation**: Each instance has its own volumes
4. **Process Isolation**: Docker provides process-level isolation

### Security Considerations

#### Privileged Mode
- **Required**: DinD container must run in privileged mode
- **Risk**: Container has elevated host access
- **Mitigation**: Use only in development/testing environments
- **Production**: Consider alternatives like Kubernetes or Docker Swarm

#### Database Security
- **Auto-generated passwords**: Strong random passwords for each instance
- **Network isolation**: MySQL not exposed to host
- **Access control**: Only WordPress container can access MySQL

#### Port Exposure
- **Minimal exposure**: Only necessary ports exposed to host
- **Dynamic ports**: Nginx uses dynamic port assignment
- **Firewall**: Consider host-level firewall rules

## Scalability

### Horizontal Scaling

The architecture supports multiple instances:

- **Pre-allocated networks**: 10 networks created on startup
- **Dynamic network creation**: Additional networks created on demand
- **Port range**: 100 ports available (8000-8099)
- **Resource limits**: Set via Docker resource constraints

### Resource Management

#### Per-Instance Limits
```yaml
services:
  mysql:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
```

#### DinD Container Limits
```yaml
wordpress-dind:
  deploy:
    resources:
      limits:
        cpus: '4.0'
        memory: 8G
```

## Performance Optimization

### Image Caching
- Base images shared across instances
- Layer caching reduces disk usage
- Faster instance creation

### Network Performance
- Bridge networks for low latency
- Direct container-to-container communication
- No NAT overhead within instance network

### Storage Performance
- Volume mounts for persistent data
- Consider using volume drivers for better performance
- SSD recommended for database volumes

## Monitoring and Logging

### Container Logs
```bash
# DinD container logs
wp-dind logs -f wordpress-dind

# Instance logs
wp-dind exec instance-manager.sh logs <instance-name>
```

### Health Checks
- DinD container: Docker daemon health check
- WordPress instances: HTTP health checks
- MySQL: Connection health checks

### Metrics Collection
Consider integrating:
- Prometheus for metrics
- Grafana for visualization
- cAdvisor for container metrics

## Disaster Recovery

### Backup Procedures
1. Stop all instances
2. Backup volumes
3. Export instance configurations
4. Document network configurations

### Recovery Procedures
1. Restore volumes
2. Recreate networks
3. Import instance configurations
4. Start instances

### High Availability
For production:
- Use Docker Swarm or Kubernetes
- Implement load balancing
- Set up database replication
- Use shared storage for volumes

## Future Enhancements

### Planned Features
- SSL/TLS certificate management
- Automated backups
- Load balancing for instances
- Monitoring dashboard
- Resource usage analytics
- Multi-host support

### Scalability Improvements
- Kubernetes deployment option
- Docker Swarm mode support
- Cloud provider integration
- Auto-scaling based on load

