# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN <<'ASH' ash -eux
    apk add --no-cache git
    git clone --depth 1 https://github.com/MoeNetwork/Tieba-Cloud-Sign .
    rm -rv setup
    chown -R www-data: .
ASH
