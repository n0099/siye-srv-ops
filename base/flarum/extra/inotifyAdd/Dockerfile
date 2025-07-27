# syntax=docker/dockerfile:1
FROM alpine:3.22

RUN --mount=type=cache,target=/etc/apk/cache <<'ASH' ash -eux
    apk add --update-cache inotify-tools libwebp-tools bash
    # same with ../../../s6.nginx.php-fpm/Dockerfile
    adduser -u 82 -h /var/www -s /sbin/nologin -S -G www-data www-data
ASH

USER www-data
WORKDIR /var/www/inotifyAdd
ENTRYPOINT exec ./inotifyAdd.sh # using shell form as exec is a shell builtin
