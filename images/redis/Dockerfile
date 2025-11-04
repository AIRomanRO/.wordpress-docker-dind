FROM redis:7.4-alpine

LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="7.4"
LABEL description="Redis 7.4 for WordPress Docker-in-Docker setup"

# Set timezone
ARG TZ=UTC
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Copy custom Redis configuration
COPY config/redis.conf /usr/local/etc/redis/redis.conf

# Create data directory
RUN mkdir -p /data && chown redis:redis /data

# Expose Redis port
EXPOSE 6379

# Use custom config
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

