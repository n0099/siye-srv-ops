# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN --mount=type=cache,target=/etc/apk/cache <<'ASH' ash -eux
    apk add --update-cache git
    git clone --recurse-submodules --depth 1 https://github.com/n0099/open-tbm .
    chown -R www-data: .
    cd be
    su www-data -s /bin/ash -c 'composer install --no-interaction'
ASH

WORKDIR /var/www/be
