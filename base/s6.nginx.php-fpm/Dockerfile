# syntax=devthefuture/dockerfile-x
FROM alpine:3.21

RUN <<'ASH' ash -eux
    # https://stackoverflow.com/questions/66507234/docker-volume-mount-and-permissions-www-data-on-host-33-becomes-xfs-33-in-a
    # https://github.com/nginxinc/docker-nginx/issues/135#issuecomment-271473009
    adduser -u 82 -h /var/www -s /sbin/nologin -S -G www-data www-data
ASH
WORKDIR /var/www

INCLUDE ./s6.Dockerfile
INCLUDE ./nginx.Dockerfile
INCLUDE ./php-fpm.Dockerfile
INCLUDE ./nginx.env.Dockerfile
INCLUDE ./cron.Dockerfile
