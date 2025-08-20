# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN --mount=type=cache,target=/etc/apk/cache \
    --mount=type=cache,target=/tmp/composer,uid=82,gid=82 \
<<'ASH' ash -eux
    apk add --update-cache git nodejs-current
    corepack enable
    git clone --recurse-submodules --depth 1 --branch prod https://github.com/n0099/open-tbm .
    chown -R www-data: .
    cd be
    su www-data -s /bin/ash -c 'composer install --no-interaction --optimize-autoloader'
ASH

WORKDIR /var/www/be
