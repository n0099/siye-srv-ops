# syntax=docker/dockerfile:1
RUN <<'ASH' ash -eux
    apk add --no-cache php83 php83-fpm php83-opcache php83-zip composer
ASH

ENV COMPOSER_HOME=/tmp/.composer

COPY ./base/s6.nginx.php-fpm/php/ /etc/php83/

ARG PHP_INI
COPY <<-INI /etc/php83/conf.d/03_Dockerfile_var.ini
	[PHP]
	$PHP_INI
INI

ARG PHP_EXTENSIONS
COPY ./base/s6.nginx.php-fpm/install-php-extensions.sh /install-php-extensions.sh
RUN <<ASH ash -eux
    /install-php-extensions.sh $PHP_EXTENSIONS
    rm -v /install-php-extensions.sh
ASH
