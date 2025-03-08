# syntax=docker/dockerfile:1
ARG CRONTAB
RUN <<ASH ash -eux
    [ -n "$CRONTAB" ] \
     && echo "$CRONTAB" > /etc/crontabs/www-data \
     || (cd /etc/s6-overlay/s6-rc.d && rm -r crond && rm user/contents.d/crond)
ASH
