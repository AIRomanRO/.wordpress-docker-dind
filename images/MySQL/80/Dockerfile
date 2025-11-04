FROM mysql:8.0.40

LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="8.0.40"
LABEL description="MySQL 8.0 for WordPress Docker-in-Docker setup"

#####################################
# Set Timezone
#####################################

ARG TZ=UTC
ENV TZ=${TZ}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && chown -R mysql:root /var/lib/mysql/

COPY my.cnf /etc/mysql/conf.d/my.cnf

RUN chmod 0444 /etc/mysql/conf.d/my.cnf

CMD ["mysqld"]

EXPOSE 3306