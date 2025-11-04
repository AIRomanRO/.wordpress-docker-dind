FROM rediscommander/redis-commander:latest

LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="latest"
LABEL description="Redis Commander - Web UI for Redis management"

# Set timezone
ARG TZ=UTC
ENV TZ=${TZ}

# Redis Commander runs on port 8081 by default
EXPOSE 8081

# Environment variables for Redis Commander
# These can be overridden at runtime
ENV REDIS_HOSTS=local:redis:6379
ENV HTTP_USER=admin
ENV HTTP_PASSWORD=admin
ENV PORT=8081

CMD ["redis-commander"]

