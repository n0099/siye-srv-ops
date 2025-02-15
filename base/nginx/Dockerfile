# syntax=docker/dockerfile:1
FROM nginx:bookworm

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

# https://github.com/devthefuture-org/dockerfile-x/issues/6#issuecomment-2143844431
COPY nginx/nginx.conf /etc/nginx/templates/default.conf.template
COPY <<'BASH' /docker-init.d/00-user.sh
    sed -iE \
        's/^user\s+nginx;$/user  www-data;/' \
        /etc/nginx/nginx.conf
BASH

COPY nginx/php-fpm.conf /etc/nginx/snippets/php-fpm.conf
COPY <<'BASH' /docker-init.d/01-resolver.sh
    # https://serverfault.com/questions/240476/how-to-force-nginx-to-resolve-dns-of-a-dynamic-hostname-everytime-when-doing-p/973311#973311
    # https://trac.nginx.org/nginx/ticket/2128
    sed -i \
        's/\$NGINX_RESOLVER/'"$(cat /etc/resolv.conf | grep -i '^nameserver' | head -n1 | cut -d' ' -f2)"/ \
        /etc/nginx/snippets/php-fpm.conf
BASH

COPY nginx/sub-base-dir.conf /etc/nginx/templates/sub-base-dir.conf
COPY <<'BASH' /docker-init.d/02-sub-base-dir.sh
    # https://superuser.com/questions/1148950/what-is-shell-format-in-envsubst
    [[ -n $NGINX_SUB_BASE_DIR ]] \
     && export NGINX_CONF_SUB_BASE_DIR="$(envsubst '$NGINX_SUB_BASE_DIR $NGINX_SUB_BASE_DIR_ALIAS' </etc/nginx/templates/sub-base-dir.conf)"
BASH

COPY <<'BASH' /docker-init.d/03-conf-extra.sh
    export NGINX_CONF_EXTRA="$(cat /etc/nginx/extra.conf)"
BASH

# https://stackoverflow.com/questions/47615751/docker-compose-run-a-script-after-container-has-started/79333020#79333020
# https://stackoverflow.com/questions/1423352/source-all-files-in-a-directory-from-bash-profile/35726215#35726215
ENTRYPOINT ["bash", "-euxo", "pipefail", "-c", "source <(cat /docker-init.d/*.sh) && exec /docker-entrypoint.sh \"$@\"", "$@"]
# https://github.com/nginxinc/docker-nginx/blob/f227279d7b5c8ae8f99d29ed61f0da4c9ac0a404/stable/debian/Dockerfile#L145
CMD ["nginx", "-g", "daemon off;"]
