#!/bin/ash -eux
[ -f /var/www/index.php ] && exit 0
cd /var/www
apk add curl
curl -LOJ https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.xz
tar xf phpMyAdmin-latest-all-languages.tar.xz
rm phpMyAdmin-latest-all-languages.tar.xz
mv phpMyAdmin-*-all-languages/* .
rm -r phpMyAdmin-*-all-languages
chown -R www-data: .
