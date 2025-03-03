# syntax=docker/dockerfile:1
RUN <<'ASH' ash -eux
    apk add --no-cache nginx gettext-envsubst moreutils
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

COPY nginx/default.conf /etc/nginx/http.d/default.conf
COPY nginx/php-fpm.conf /etc/nginx/snippets/php-fpm.conf
COPY nginx/sub-base-dir.conf /etc/nginx/templates/sub-base-dir.conf
