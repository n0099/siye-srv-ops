# syntax=docker/dockerfile:1
RUN <<'ASH' ash -eux
    apk add --no-cache nginx gettext-envsubst moreutils
    # https://gitlab.alpinelinux.org/alpine/aports/-/blob/fc9c41ba44793e8306b33f9342da2efea990a562/main/nginx/APKBUILD#L425
    # https://gitlab.alpinelinux.org/alpine/aports/-/commit/968b8aa5e3dcade268c50c9c1299693d4e2255a1#1c844066a21a81a5cd7e662e89608aea1bf96d68_74_89
    rm -rv /var/www/localhost
ASH

# https://docs.docker.com/build/building/variables/#env-usage-example
ARG NGINX_DOMAIN
ENV NGINX_DOMAIN=$NGINX_DOMAIN
ARG NGINX_ROOT
ENV NGINX_ROOT=$NGINX_ROOT

# used by ./nginx.conf
ARG NGINX_CONF
ENV NGINX_CONF=$NGINX_CONF
ARG NGINX_SUB_BASE_DIR
ENV NGINX_SUB_BASE_DIR=$NGINX_SUB_BASE_DIR
ARG NGINX_SUB_BASE_DIR_ALIAS
ENV NGINX_SUB_BASE_DIR_ALIAS=$NGINX_SUB_BASE_DIR_ALIAS

COPY ./base/s6.nginx.php-fpm/nginx /etc/nginx
