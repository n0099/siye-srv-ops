# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN --mount=type=cache,target=/tmp/composer,uid=82,gid=82 \
<<'ASH' ash -eux
    su www-data -s /bin/ash -c 'composer create-project --no-interaction --no-dev flarum/flarum:^1.8 .'
ASH
