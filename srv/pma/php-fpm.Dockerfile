# syntax=devthefuture/dockerfile-x:1
INCLUDE php-fpm/Dockerfile

WORKDIR /var/www/html
RUN <<'DASH' dash -eux
    curl -LOJ https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.xz
    tar xvf phpMyAdmin-latest-all-languages.tar.xz
    rm phpMyAdmin-latest-all-languages.tar.xz
    mv phpMyAdmin-*-all-languages/* .
    rm -r phpMyAdmin-*-all-languages
DASH
