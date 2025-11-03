FROM alpine:3.20

LABEL maintainer="aur3l.roman@gmail.com"
LABEL version="0.10.0"
LABEL description="MailCatcher for WordPress Docker-in-Docker setup"

ENV MAIL_CATCHER_VERSION=0.10.0
ENV MAIL_CATCHER_SMTP_PORT=1025
ENV MAIL_CATCHER_HTTP_PORT=1080

RUN apk add --update ruby ruby-dev ruby-etc ruby-bigdecimal sqlite sqlite-dev build-base libstdc++ ca-certificates && \
    gem install json --no-document && \
    gem install mailcatcher -v ${MAIL_CATCHER_VERSION} --no-document && \
    apk del --purge ruby-dev build-base && \
    rm -rf /var/cache/apk/*

EXPOSE ${MAIL_CATCHER_SMTP_PORT} ${MAIL_CATCHER_HTTP_PORT}

CMD mailcatcher -f --ip=0.0.0.0 --smtp-port=${MAIL_CATCHER_SMTP_PORT} --http-port=${MAIL_CATCHER_HTTP_PORT}