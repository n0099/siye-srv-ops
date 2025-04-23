# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN <<'ASH' ash -eux
    apk add --no-cache git
    git clone --recurse-submodules --depth 1 https://github.com/n0099/open-tbm .
    chown -R www-data: .
    cd be
    su www-data -s /bin/ash -c 'composer install --no-interaction'
ASH

WORKDIR /var/www/be
