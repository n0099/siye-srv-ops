#!/bin/ash -eux
cd /var/www
[ -f index.php ] && exit 0

apk add --no-cache curl
curl -LOJ https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.xz
tar xf phpMyAdmin-latest-all-languages.tar.xz
rm phpMyAdmin-latest-all-languages.tar.xz
mv phpMyAdmin-*-all-languages/* .
rm -r phpMyAdmin-*-all-languages
chown -R www-data: .
