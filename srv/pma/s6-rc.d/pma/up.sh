#!/bin/ash -eux
cd /var/www
[ -f index.php ] && exit 0

apk add --no-cache curl
curl -LOJ https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.xz
tar xf phpMyAdmin-latest-all-languages.tar.xz
rm -v phpMyAdmin-latest-all-languages.tar.xz
mv -v phpMyAdmin-*-all-languages/* .
rm -rv phpMyAdmin-*-all-languages
chown -R www-data: .
