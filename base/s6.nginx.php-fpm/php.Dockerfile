# syntax=docker/dockerfile:1
RUN --mount=type=cache,target=/etc/apk/cache <<'ASH' ash -eux
    apk add --update-cache php84 php84-fpm php84-opcache \
        `# depends of https://pkgs.alpinelinux.org/package/v3.22/community/x86_64/composer` \
        php84-phar php84-curl php84-iconv php84-mbstring php84-openssl php84-zip
    # https://pkgs.alpinelinux.org/contents?file=php&branch=v3.22&arch=x86_64
    ln -s /usr/bin/php84 /usr/local/bin/php
ASH

# https://gitlab.alpinelinux.org/alpine/aports/-/issues/15554
COPY --from=composer:2.8.10 /usr/bin/composer /usr/local/bin/composer
ENV COMPOSER_HOME=/tmp/composer

COPY ./base/s6.nginx.php-fpm/php/ /etc/php84/

ARG PHP_INI
COPY <<-INI /etc/php84/conf.d/03_Dockerfile_var.ini
	[PHP]
	$PHP_INI
INI

ARG PHP_EXTENSIONS
COPY ./base/s6.nginx.php-fpm/install-php-extensions.sh /install-php-extensions.sh
RUN --mount=type=cache,target=/etc/apk/cache <<ASH ash -eux
    /install-php-extensions.sh $PHP_EXTENSIONS
    rm -v /install-php-extensions.sh
ASH
