# Installation Guide

This guide walks you through the complete installation and setup of the WordPress Docker-in-Docker environment.

## Prerequisites

### System Requirements

- **Operating System**: Linux, macOS, or Windows with WSL2
- **RAM**: Minimum 8GB, recommended 16GB or more
- **Disk Space**: Minimum 20GB free space
- **CPU**: Multi-core processor recommended

### Software Requirements

1. **Docker Engine**
   - Version: 20.10 or higher
   - Installation: https://docs.docker.com/engine/install/

2. **docker-compose**
   - Version: 1.29 or higher
   - Installation: https://docs.docker.com/compose/install/

3. **Node.js**
   - Version: 18.0 or higher
   - Installation: https://nodejs.org/

4. **Git** (optional, for cloning repository)
   - Installation: https://git-scm.com/downloads

## Installation Steps

### Step 1: Clone or Download the Repository

#### Option A: Clone with Git
```bash
git clone https://github.com/yourusername/wordpress-docker-dind.git
cd wordpress-docker-dind
```

#### Option B: Download ZIP
1. Download the repository as ZIP
2. Extract to your desired location
3. Navigate to the directory

### Step 2: Verify Docker Installation

```bash
# Check Docker version
docker --version
# Expected output: Docker version 20.10.x or higher

# Check docker-compose version
docker-compose --version
# Expected output: docker-compose version 1.29.x or higher

# Verify Docker is running
docker info
# Should display Docker system information
```

### Step 3: Build Docker Images

Build all required Docker images with proper version tags:

```bash
# Make the build script executable
chmod +x build-images.sh

# Run the build script
./build-images.sh
```

This will build:
- MySQL 5.6.51, 5.7.44, 8.0.40
- Nginx 1.27
- phpMyAdmin 5.2.3
- MailCatcher 0.10.0
- Docker-in-Docker 27.0

**Expected output:**
```
========================================
WordPress Docker-in-Docker Image Builder
========================================

Building MySQL images...
Building wp-mysql:5.6.51...
  ✓ wp-mysql:5.6.51 built successfully

Building wp-mysql:5.7.44...
  ✓ wp-mysql:5.7.44 built successfully

Building wp-mysql:8.0.40...
  ✓ wp-mysql:8.0.40 built successfully

...

========================================
All images built successfully!
========================================
```

**Build time**: Approximately 10-20 minutes depending on your system and internet connection.

### Step 4: Verify Built Images

```bash
docker images | grep -E "wp-mysql|wp-nginx|wp-phpmyadmin|wp-mailcatcher|wp-dind"
```

**Expected output:**
```
wp-dind          27.0      abc123def456   2 minutes ago   250MB
wp-dind          27        abc123def456   2 minutes ago   250MB
wp-dind          latest    abc123def456   2 minutes ago   250MB
wp-mailcatcher   0.10.0    def456ghi789   3 minutes ago   180MB
wp-mailcatcher   latest    def456ghi789   3 minutes ago   180MB
wp-phpmyadmin    5.2.3     ghi789jkl012   4 minutes ago   520MB
wp-phpmyadmin    latest    ghi789jkl012   4 minutes ago   520MB
wp-nginx         1.27      jkl012mno345   5 minutes ago   45MB
wp-nginx         latest    jkl012mno345   5 minutes ago   45MB
wp-mysql         8.0.40    mno345pqr678   6 minutes ago   580MB
wp-mysql         8.0       mno345pqr678   6 minutes ago   580MB
wp-mysql         8         mno345pqr678   6 minutes ago   580MB
wp-mysql         latest    mno345pqr678   6 minutes ago   580MB
wp-mysql         5.7.44    pqr678stu901   7 minutes ago   450MB
wp-mysql         5.7       pqr678stu901   7 minutes ago   450MB
wp-mysql         57        pqr678stu901   7 minutes ago   450MB
wp-mysql         5.6.51    stu901vwx234   8 minutes ago   320MB
wp-mysql         5.6       stu901vwx234   8 minutes ago   320MB
wp-mysql         56        stu901vwx234   8 minutes ago   320MB
```

### Step 5: Install Global CLI Tool

```bash
# Navigate to CLI tool directory
cd cli-tool

# Install dependencies
npm install

# Install globally
npm install -g .

# Verify installation
wp-dind --version
```

**Expected output:**
```
1.0.0
```

**Troubleshooting**: If `wp-dind` command is not found:

1. Check npm global bin directory:
   ```bash
   npm config get prefix
   ```

2. Add to your PATH (add to ~/.bashrc or ~/.zshrc):
   ```bash
   export PATH="$(npm config get prefix)/bin:$PATH"
   ```

3. Reload your shell:
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

### Step 6: Test the Installation

#### Option A: Using docker-compose (Direct)

```bash
# Navigate back to project root
cd ..

# Start the environment
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f wordpress-dind

# Stop the environment
docker-compose stop
```

#### Option B: Using CLI Tool (Recommended)

```bash
# Create a test project
mkdir ~/test-wordpress-dind
cd ~/test-wordpress-dind

# Initialize the environment
wp-dind init

# Start the environment
wp-dind start

# Check status
wp-dind status

# Stop the environment
wp-dind stop
```

## Post-Installation Configuration

### Configure Docker (Linux)

If you're on Linux and want to run Docker without sudo:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER

# Log out and back in for changes to take effect
# Or run:
newgrp docker

# Verify
docker ps
```

### Configure Resource Limits

Edit `docker-compose.yml` to adjust resource limits:

```yaml
services:
  wordpress-dind:
    deploy:
      resources:
        limits:
          cpus: '4.0'
          memory: 8G
        reservations:
          cpus: '2.0'
          memory: 4G
```

### Configure Port Ranges

Edit `docker-compose.yml` to change exposed ports:

```yaml
ports:
  - "2375:2375"           # Docker daemon
  - "8000-8099:8000-8099" # WordPress instances
```

For phpMyAdmin and MailCatcher:

```yaml
phpmyadmin:
  ports:
    - "8080:80"  # Change 8080 to your preferred port

mailcatcher:
  ports:
    - "1080:1080"  # Web UI
    - "1025:1025"  # SMTP
```

## Creating Your First WordPress Instance

### Step 1: Start the DinD Environment

```bash
# Using CLI tool
wp-dind start

# Or using docker-compose
docker-compose up -d
```

### Step 2: Wait for DinD to be Ready

```bash
# Check health status
docker ps

# Wait for "healthy" status
# Or check logs
wp-dind logs -f wordpress-dind
```

Look for:
```
Docker daemon is ready!
Docker-in-Docker WordPress environment is ready!
```

### Step 3: Create a WordPress Instance

```bash
# Create instance with MySQL 8.0
wp-dind exec instance-manager.sh create mysite 80

# Or with MySQL 5.7
wp-dind exec instance-manager.sh create mysite 57
```

**Expected output:**
```
Creating WordPress instance: mysite
Instance 'mysite' created successfully!
Instance directory: /wordpress-instances/mysite
Network: wp-network-1

To start the instance, run:
  instance-manager.sh start mysite
```

### Step 4: Start the WordPress Instance

```bash
wp-dind exec instance-manager.sh start mysite
```

**Expected output:**
```
Starting WordPress instance: mysite
Creating mysite-mysql ... done
Creating mysite-wordpress ... done
Creating mysite-nginx ... done
Instance 'mysite' started successfully!
Access WordPress at: http://localhost:8001
```

### Step 5: Access WordPress

1. Open your browser
2. Navigate to the URL shown (e.g., http://localhost:8001)
3. Complete WordPress installation wizard

### Step 6: Get Instance Information

```bash
wp-dind exec instance-manager.sh info mysite
```

**Expected output:**
```
Instance Information: mysite
================================
Name: mysite
MySQL Version: 80
Network: wp-network-1
Created: 2025-11-03T10:00:00+00:00
Instance Directory: /wordpress-instances/mysite

Database Credentials:
  Database: wordpress
  User: wordpress
  Password: <auto-generated-password>
  Root Password: <auto-generated-root-password>

Status: Running

Containers:
NAMES              STATUS              PORTS
mysite-nginx       Up 2 minutes        0.0.0.0:8001->80/tcp
mysite-wordpress   Up 2 minutes        9000/tcp
mysite-mysql       Up 2 minutes        3306/tcp

Access URL: http://localhost:8001
```

## Accessing Support Services

### phpMyAdmin

1. Open browser: http://localhost:8080
2. Server: Enter the MySQL container name (e.g., `mysite-mysql`)
3. Username: `wordpress` or `root`
4. Password: Use the password from instance info

### MailCatcher

1. Open browser: http://localhost:1080
2. Configure WordPress to use SMTP:
   - Host: `mailcatcher`
   - Port: `1025`
   - No authentication required

## Verification Checklist

- [ ] Docker and docker-compose installed and running
- [ ] All Docker images built successfully
- [ ] CLI tool installed globally
- [ ] DinD environment starts without errors
- [ ] WordPress instance created successfully
- [ ] WordPress accessible in browser
- [ ] phpMyAdmin accessible
- [ ] MailCatcher accessible

## Next Steps

1. Read the [Architecture Documentation](ARCHITECTURE.md)
2. Learn about [Network Configuration](NETWORK.md)
3. Explore [Image Management](IMAGES.md)
4. Review [Troubleshooting Guide](TROUBLESHOOTING.md)

## Uninstallation

### Remove CLI Tool

```bash
npm uninstall -g wp-dind-cli
```

### Remove Docker Images

```bash
# Remove all wp-* images
docker rmi $(docker images | grep "^wp-" | awk '{print $1":"$2}')
```

### Remove Volumes

```bash
# Stop and remove containers
docker-compose down -v

# Remove named volumes
docker volume rm wordpress-instances dind-docker-data phpmyadmin-sessions
```

### Remove Project Files

```bash
cd ..
rm -rf wordpress-docker-dind
```

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Review Docker logs: `wp-dind logs -f`
3. Check instance logs: `wp-dind exec instance-manager.sh logs <instance-name>`
4. Verify Docker is running: `docker info`
5. Check available resources: `docker system df`

## Support

For additional support:
- Email: aur3l.roman@gmail.com
- GitHub Issues: [Create an issue](https://github.com/yourusername/wordpress-docker-dind/issues)

