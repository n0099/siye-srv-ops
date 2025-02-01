# syntax=devthefuture/dockerfile-x:1
INCLUDE nginx/Dockerfile

# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND=noninteractive

RUN <<'DASH' dash -eux
    apt-get update
    apt-get install -y php8.2 composer
DASH
WORKDIR /var/www/html
# https://github.com/composer/composer/issues/680
# https://getcomposer.org/doc/03-cli.md#environment-variables
ENV COMPOSER_HOME=/tmp/.composer \
    COMPOSER_NO_DEV=1

# https://github.com/devthefuture-org/dockerfile-x/issues/6#issuecomment-2143844431
COPY flarum/10-composer-create.sh /docker-init.d/10-composer-create.sh
RUN <<'DASH' dash -eux
    . /docker-init.d/10-composer-create.sh
    rm /docker-init.d/10-composer-create.sh
DASH

COPY flarum/20-composer-install.sh /docker-init.d/20-composer-install.sh
RUN <<'DASH' dash -eux
    # we don't really run php in the nginx container so ignore missing php extensions
    sed -i 's/composer install/& --ignore-platform-reqs/' /docker-init.d/20-composer-install.sh
DASH
