#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}WordPress Docker-in-Docker Image Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to build an image with tags
build_image() {
    local context=$1
    local image_name=$2
    local version=$3
    local additional_tags=("${@:4}")
    
    echo -e "${GREEN}Building ${image_name}:${version}...${NC}"
    
    # Build the image
    docker build -t "${image_name}:${version}" "$context"
    
    # Tag as latest
    docker tag "${image_name}:${version}" "${image_name}:latest"
    
    # Add any additional tags
    for tag in "${additional_tags[@]}"; do
        if [ -n "$tag" ]; then
            docker tag "${image_name}:${version}" "${image_name}:${tag}"
            echo -e "${YELLOW}  Tagged as ${image_name}:${tag}${NC}"
        fi
    done
    
    echo -e "${GREEN}  ✓ ${image_name}:${version} built successfully${NC}"
    echo ""
}

# Build MySQL images
echo -e "${BLUE}Building MySQL images...${NC}"
build_image "./images/MySQL/56" "wp-mysql" "5.6.51" "56" "5.6"
build_image "./images/MySQL/57" "wp-mysql" "5.7.44" "57" "5.7"
build_image "./images/MySQL/80" "wp-mysql" "8.0.40" "80" "8.0" "8"

# Build PHP images
echo -e "${BLUE}Building PHP-FPM images...${NC}"
build_image "./images/php/7.4" "wp-php" "7.4" "74"
build_image "./images/php/8.0" "wp-php" "8.0" "80"
build_image "./images/php/8.1" "wp-php" "8.1" "81"
build_image "./images/php/8.2" "wp-php" "8.2" "82"
build_image "./images/php/8.3" "wp-php" "8.3" "83"

# Build Nginx image
echo -e "${BLUE}Building Nginx image...${NC}"
build_image "./images/nginx" "wp-nginx" "1.27" "1.27-alpine"

# Build Apache image
echo -e "${BLUE}Building Apache image...${NC}"
build_image "./images/apache" "wp-apache" "2.4" "2.4-alpine"

# Build phpMyAdmin image
echo -e "${BLUE}Building phpMyAdmin image...${NC}"
build_image "./images/phpMyAdmin" "wp-phpmyadmin" "5.2.3"

# Build MailCatcher image
echo -e "${BLUE}Building MailCatcher image...${NC}"
build_image "./images/mailCatcher" "wp-mailcatcher" "0.10.0"

# Build Docker-in-Docker image
echo -e "${BLUE}Building Docker-in-Docker image...${NC}"
build_image "./images/docker-dind-wp" "wp-dind" "27.0" "27"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}All images built successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}Available images:${NC}"
docker images | grep -E "wp-mysql|wp-php|wp-nginx|wp-apache|wp-phpmyadmin|wp-mailcatcher|wp-dind" | sort

echo ""
echo -e "${BLUE}Image Summary:${NC}"
echo -e "  • wp-mysql:5.6.51, wp-mysql:56, wp-mysql:5.6"
echo -e "  • wp-mysql:5.7.44, wp-mysql:57, wp-mysql:5.7"
echo -e "  • wp-mysql:8.0.40, wp-mysql:80, wp-mysql:8.0, wp-mysql:8, wp-mysql:latest"
echo -e "  • wp-php:7.4, wp-php:74"
echo -e "  • wp-php:8.0, wp-php:80"
echo -e "  • wp-php:8.1, wp-php:81"
echo -e "  • wp-php:8.2, wp-php:82"
echo -e "  • wp-php:8.3, wp-php:83, wp-php:latest"
echo -e "  • wp-nginx:1.27, wp-nginx:1.27-alpine, wp-nginx:latest"
echo -e "  • wp-apache:2.4, wp-apache:2.4-alpine, wp-apache:latest"
echo -e "  • wp-phpmyadmin:5.2.3, wp-phpmyadmin:latest"
echo -e "  • wp-mailcatcher:0.10.0, wp-mailcatcher:latest"
echo -e "  • wp-dind:27.0, wp-dind:27, wp-dind:latest"
echo ""
echo -e "${GREEN}To start the environment, run:${NC}"
echo -e "  docker-compose up -d"
echo ""

