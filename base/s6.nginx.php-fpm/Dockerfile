# syntax=devthefuture/dockerfile-x
FROM alpine:3.21

RUN <<'ASH' ash -eux
    adduser -S www-data -G www-data -h /var/www -s /sbin/nologin
ASH
WORKDIR /var/www

INCLUDE ./s6.Dockerfile
INCLUDE ./nginx.Dockerfile
INCLUDE ./php-fpm.Dockerfile
INCLUDE ./cron.Dockerfile
