# syntax=devthefuture/dockerfile-x
FROM ./base/s6.nginx.php-fpm/Dockerfile

RUN <<ASH ash -eux
    apk add --no-cache git
    git clone --depth 1 --branch v1 https://github.com/n0099/open-tbm .
    rm -rv contribution.php core.php cron.php jieba* pic* reply.php rss.php sitemap.php test.php
ASH
