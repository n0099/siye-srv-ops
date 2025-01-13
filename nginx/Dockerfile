# syntax=docker/dockerfile:1
FROM nginx:bookworm

# https://github.com/devthefuture-org/dockerfile-x/issues/6#issuecomment-2143844431
COPY nginx/nginx.conf /etc/nginx/templates/default.conf.template

# https://docs.docker.com/build/building/variables/#env-usage-example
ARG NGINX_DOMAIN
ENV NGINX_DOMAIN=$NGINX_DOMAIN
ARG NGINX_ROOT
ENV NGINX_ROOT=$NGINX_ROOT
# used by ./nginx.conf
ARG NGINX_CONF
ENV NGINX_CONF=$NGINX_CONF

COPY <<'BASH' /docker-init.d/00-env.sh
    test -n "$NGINX_DOMAIN"
    test -n "$NGINX_ROOT"
    test -n "$NGINX_CONF"
BASH
COPY <<'BASH' /docker-init.d/01-user.sh
    sed -iE 's/^user\s+nginx;$/user  www-data;/' /etc/nginx/nginx.conf
BASH
COPY <<'BASH' /docker-init.d/02-resolver.sh
    # https://serverfault.com/questions/240476/how-to-force-nginx-to-resolve-dns-of-a-dynamic-hostname-everytime-when-doing-p/973311#973311
    export NGINX_RESOLVER="$(cat /etc/resolv.conf | grep -i '^nameserver' | head -n1 | cut -d' ' -f2)"
BASH

# https://stackoverflow.com/questions/47615751/docker-compose-run-a-script-after-container-has-started/79333020#79333020
# https://stackoverflow.com/questions/1423352/source-all-files-in-a-directory-from-bash-profile/35726215#35726215
ENTRYPOINT ["bash", "-xc", "source <(cat /docker-init.d/*.sh) && exec /docker-entrypoint.sh \"$@\"", "$@"]
# https://github.com/nginxinc/docker-nginx/blob/f227279d7b5c8ae8f99d29ed61f0da4c9ac0a404/stable/debian/Dockerfile#L145
CMD ["nginx", "-g", "daemon off;"]
