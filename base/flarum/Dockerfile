# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN <<'ASH' ash -eux
    su www-data -s /bin/ash -c 'composer create-project --no-interaction --no-dev flarum/flarum:^1.8 .'
ASH
