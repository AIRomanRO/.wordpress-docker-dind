# Network Configuration Guide

This document explains the network architecture and configuration options for the WordPress Docker-in-Docker environment.

## Network Overview

The WordPress DinD environment uses a multi-layered network architecture to provide isolation, security, and flexibility.

## Network Layers

### Layer 1: Host Network

The host system's network that connects to the outside world.

**Configuration**: Managed by your operating system

**Exposed Ports**:
- `2375`: Docker daemon (DinD container)
- `8000-8099`: WordPress instances (dynamically assigned)
- `8080`: phpMyAdmin
- `1080`: MailCatcher Web UI
- `1025`: MailCatcher SMTP

### Layer 2: DinD Bridge Network

**Name**: `wordpress-dind-network`  
**Subnet**: `172.19.0.0/16`  
**Driver**: bridge

**Purpose**: Connects the DinD container with support services (phpMyAdmin, MailCatcher)

**Connected Services**:
- wordpress-dind-host
- phpmyadmin
- mailcatcher

**Configuration** (docker-compose.yml):
```yaml
networks:
  wordpress-dind-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.19.0.0/16
```

### Layer 3: Shared Network (Inside DinD)

**Name**: `wp-shared`  
**Subnet**: `172.21.0.0/16`  
**Driver**: bridge

**Purpose**: Optional network for inter-instance communication

**Use Cases**:
- Multi-site WordPress setups
- Instances that need to communicate
- Shared services between instances

**Creation**:
```bash
# Automatically created by network-setup.sh
docker network create \
  --driver bridge \
  --subnet 172.21.0.0/16 \
  --opt com.docker.network.bridge.name=wp-shared \
  wp-shared
```

### Layer 4: Instance Networks (Inside DinD)

**Name Pattern**: `wp-network-{N}`  
**Subnet Pattern**: `172.20.{N}.0/24`  
**Driver**: bridge

**Purpose**: Isolated network for each WordPress instance

**Example**:
- Instance 1: `wp-network-1` (172.20.1.0/24)
- Instance 2: `wp-network-2` (172.20.2.0/24)
- Instance 3: `wp-network-3` (172.20.3.0/24)

**Creation**:
```bash
# Automatically created by instance-manager.sh
docker network create \
  --driver bridge \
  --subnet 172.20.1.0/24 \
  --opt com.docker.network.bridge.name=wp-br-1 \
  wp-network-1
```

## Network Isolation

### Default Isolation

By default, each WordPress instance is completely isolated:

```
Instance 1 (172.20.1.0/24)
├── MySQL:      172.20.1.2
├── WordPress:  172.20.1.3
└── Nginx:      172.20.1.4

Instance 2 (172.20.2.0/24)
├── MySQL:      172.20.2.2
├── WordPress:  172.20.2.3
└── Nginx:      172.20.2.4
```

**Benefits**:
- Security: Instances cannot access each other
- Stability: Issues in one instance don't affect others
- Flexibility: Each instance can use the same port numbers
- Testing: Safe environment for testing changes

### Enabling Inter-Instance Communication

To allow instances to communicate:

#### Method 1: Connect to Shared Network

```bash
# Connect instance 1 to shared network
wp-dind exec docker network connect wp-shared mysite1-wordpress

# Connect instance 2 to shared network
wp-dind exec docker network connect wp-shared mysite2-wordpress

# Now instances can communicate via shared network
```

#### Method 2: Custom Network Bridge

```bash
# Create a custom network
wp-dind exec docker network create \
  --driver bridge \
  --subnet 172.22.0.0/16 \
  custom-shared

# Connect instances
wp-dind exec docker network connect custom-shared mysite1-wordpress
wp-dind exec docker network connect custom-shared mysite2-wordpress
```

## Port Management

### Dynamic Port Assignment

WordPress instances use dynamic port assignment for external access:

```yaml
services:
  nginx:
    ports:
      - "0:80"  # Docker assigns a random available port
```

**Finding Assigned Port**:
```bash
# Using instance manager
wp-dind exec instance-manager.sh info mysite

# Using Docker directly
wp-dind exec docker port mysite-nginx 80
```

### Static Port Assignment

To assign a specific port to an instance:

1. Edit the instance's docker-compose.yml:
```bash
wp-dind exec vi /wordpress-instances/mysite/docker-compose.yml
```

2. Change the port mapping:
```yaml
services:
  nginx:
    ports:
      - "8001:80"  # Static port 8001
```

3. Restart the instance:
```bash
wp-dind exec instance-manager.sh stop mysite
wp-dind exec instance-manager.sh start mysite
```

### Port Range Configuration

The DinD container exposes a port range for WordPress instances:

```yaml
ports:
  - "8000-8099:8000-8099"
```

**To change the range**:

1. Edit `docker-compose.yml`:
```yaml
ports:
  - "9000-9199:9000-9199"  # 200 ports instead of 100
```

2. Restart the DinD container:
```bash
docker-compose restart wordpress-dind
```

## Network Security

### Firewall Rules

#### Host-Level Firewall

Restrict access to DinD services:

```bash
# Allow only localhost to access phpMyAdmin
sudo iptables -A INPUT -p tcp --dport 8080 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8080 -j DROP

# Allow specific IP range to access WordPress instances
sudo iptables -A INPUT -p tcp --dport 8000:8099 -s 192.168.1.0/24 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 8000:8099 -j DROP
```

#### Docker Network Policies

Implement network policies using Docker:

```bash
# Create a network with custom driver options
docker network create \
  --driver bridge \
  --opt com.docker.network.bridge.enable_icc=false \
  --opt com.docker.network.bridge.enable_ip_masquerade=true \
  isolated-network
```

### SSL/TLS Configuration

#### Using Nginx as SSL Termination

1. Generate SSL certificates:
```bash
# Self-signed certificate (development)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /path/to/nginx/ssl/nginx.key \
  -out /path/to/nginx/ssl/nginx.crt
```

2. Update nginx configuration:
```nginx
server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;
    
    # ... rest of configuration
}
```

3. Mount SSL certificates:
```yaml
services:
  nginx:
    volumes:
      - ./ssl:/etc/nginx/ssl:ro
```

## Advanced Network Configurations

### Custom DNS

Configure custom DNS for instances:

```yaml
services:
  wordpress:
    dns:
      - 8.8.8.8
      - 8.8.4.4
```

### Network Aliases

Add network aliases for easier service discovery:

```yaml
services:
  mysql:
    networks:
      wp-network-1:
        aliases:
          - database
          - db
          - mysql-server
```

### IPv6 Support

Enable IPv6 for networks:

```yaml
networks:
  wordpress-dind-network:
    driver: bridge
    enable_ipv6: true
    ipam:
      config:
        - subnet: 172.19.0.0/16
        - subnet: 2001:db8:1::/64
```

### Network Bandwidth Limiting

Limit network bandwidth for instances:

```bash
# Install tc (traffic control)
apt-get install iproute2

# Limit bandwidth to 10Mbit/s
tc qdisc add dev eth0 root tbf rate 10mbit burst 32kbit latency 400ms
```

## Troubleshooting Network Issues

### Check Network Connectivity

```bash
# List all networks
wp-dind exec docker network ls

# Inspect a network
wp-dind exec docker network inspect wp-network-1

# Check container connectivity
wp-dind exec docker exec mysite-wordpress ping -c 3 mysite-mysql
```

### DNS Resolution Issues

```bash
# Check DNS resolution
wp-dind exec docker exec mysite-wordpress nslookup mysite-mysql

# Test with dig
wp-dind exec docker exec mysite-wordpress dig mysite-mysql
```

### Port Conflicts

```bash
# Check which ports are in use
netstat -tuln | grep LISTEN

# Find process using a port
lsof -i :8080

# Kill process using a port
kill -9 $(lsof -t -i:8080)
```

### Network Performance

```bash
# Test network speed between containers
wp-dind exec docker exec mysite-wordpress \
  wget -O /dev/null http://mysite-nginx

# Monitor network traffic
docker stats mysite-nginx mysite-wordpress mysite-mysql
```

## Network Monitoring

### Real-time Monitoring

```bash
# Monitor network traffic
docker stats --format "table {{.Container}}\t{{.NetIO}}"

# Watch network connections
watch -n 1 'docker exec mysite-nginx netstat -an | grep ESTABLISHED'
```

### Network Metrics

```bash
# Get detailed network stats
docker inspect mysite-nginx | jq '.[0].NetworkSettings'

# Check network bandwidth usage
docker stats --no-stream --format \
  "table {{.Container}}\t{{.NetIO}}" mysite-nginx
```

## Best Practices

### Network Design

1. **Use isolated networks by default**: Keep instances separated
2. **Minimize exposed ports**: Only expose necessary ports to host
3. **Use internal networks**: For services that don't need external access
4. **Implement network policies**: Use firewall rules and Docker network options
5. **Monitor network traffic**: Regularly check for unusual activity

### Security

1. **Don't expose Docker daemon**: Keep port 2375 internal or use TLS
2. **Use strong passwords**: For database and admin interfaces
3. **Implement SSL/TLS**: For production environments
4. **Regular updates**: Keep Docker and images up to date
5. **Network segmentation**: Separate development and production networks

### Performance

1. **Use bridge networks**: Better performance than overlay networks
2. **Minimize network hops**: Direct container-to-container communication
3. **Optimize MTU**: Match host network MTU
4. **Use connection pooling**: For database connections
5. **Monitor bandwidth**: Identify and resolve bottlenecks

## Network Configuration Examples

### Example 1: Completely Isolated Instances

```yaml
# Each instance in its own network
# No inter-instance communication
# Default configuration
```

### Example 2: Shared Database Server

```yaml
# One MySQL server for multiple WordPress instances
# All instances connected to shared network
networks:
  - wp-shared

services:
  mysql:
    networks:
      - wp-shared
  
  wordpress1:
    networks:
      - wp-shared
  
  wordpress2:
    networks:
      - wp-shared
```

### Example 3: Multi-tier Architecture

```yaml
# Separate networks for different tiers
networks:
  frontend:
    subnet: 172.20.1.0/24
  backend:
    subnet: 172.20.2.0/24

services:
  nginx:
    networks:
      - frontend
  
  wordpress:
    networks:
      - frontend
      - backend
  
  mysql:
    networks:
      - backend
```

## References

- [Docker Networking Documentation](https://docs.docker.com/network/)
- [Docker Compose Networking](https://docs.docker.com/compose/networking/)
- [Bridge Network Driver](https://docs.docker.com/network/bridge/)

