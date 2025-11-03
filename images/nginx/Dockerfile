FROM nginx:1.27-alpine

LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="1.27"
LABEL description="Nginx for WordPress Docker-in-Docker setup"

RUN mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.disabled

EXPOSE 80 443