# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

ADD --checksum=sha256:f881819a3b11e653b0212afaf0cc105db85c767715cb3f5852670f7fc36c9669 https://files.phpmyadmin.net/phpMyAdmin/5.2.2/phpMyAdmin-5.2.2-all-languages.tar.xz .
RUN <<-ASH ash -eux
    tar xf phpMyAdmin-*-all-languages.tar.xz
    rm -v phpMyAdmin-*-all-languages.tar.xz
    mv -v phpMyAdmin-*-all-languages/* .
    rm -rv phpMyAdmin-*-all-languages
    chown -R www-data: .
ASH
