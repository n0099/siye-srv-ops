# syntax=devthefuture/dockerfile-x
FROM alpine:3.21

RUN <<'ASH' ash -eux
    adduser -S www-data -G www-data -h /var/www/html -s /sbin/nologin
ASH

INCLUDE ./s6.Dockerfile
INCLUDE ./nginx.Dockerfile
INCLUDE ./php-fpm.Dockerfile
