FROM httpd:2.4-alpine

LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="2.4"
LABEL description="Apache 2.4 for WordPress Docker-in-Docker setup"

# Install required packages
RUN apk add --no-cache \
    bash \
    curl \
    apache2-proxy \
    apache2-proxy-html

# Enable required Apache modules
RUN sed -i \
    -e 's/^#\(LoadModule .*mod_rewrite.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_proxy_fcgi.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_headers.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_expires.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_deflate.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_ssl.so\)/\1/' \
    -e 's/^#\(LoadModule .*mod_socache_shmcb.so\)/\1/' \
    /usr/local/apache2/conf/httpd.conf

# Update Apache configuration for WordPress
RUN sed -i \
    -e 's/AllowOverride None/AllowOverride All/' \
    -e 's/DirectoryIndex index.html/DirectoryIndex index.php index.html/' \
    /usr/local/apache2/conf/httpd.conf

# Create directory for custom configurations
RUN mkdir -p /usr/local/apache2/conf/sites-enabled

# Add include for custom site configurations
RUN echo "Include conf/sites-enabled/*.conf" >> /usr/local/apache2/conf/httpd.conf

# Set proper permissions
RUN chown -R www-data:www-data /usr/local/apache2/htdocs

# Expose HTTP and HTTPS ports
EXPOSE 80 443

# Set working directory
WORKDIR /usr/local/apache2/htdocs

CMD ["httpd-foreground"]

