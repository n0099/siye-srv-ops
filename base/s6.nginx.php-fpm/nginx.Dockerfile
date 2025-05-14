# syntax=docker/dockerfile:1
RUN --mount=type=cache,target=/etc/apk/cache <<'ASH' ash -eux
    apk add --update-cache nginx gettext-envsubst moreutils
    # https://gitlab.alpinelinux.org/alpine/aports/-/blob/fc9c41ba44793e8306b33f9342da2efea990a562/main/nginx/APKBUILD#L425
    # https://gitlab.alpinelinux.org/alpine/aports/-/commit/968b8aa5e3dcade268c50c9c1299693d4e2255a1#1c844066a21a81a5cd7e662e89608aea1bf96d68_74_89
    rm -rv /var/www/localhost
ASH

COPY ./base/s6.nginx.php-fpm/nginx/ /etc/nginx/
