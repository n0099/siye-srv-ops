# syntax=devthefuture/dockerfile-x:1
INCLUDE nginx/Dockerfile

RUN <<'DASH'
    apt-get update
    apt-get install -y sudo php8.2 composer
DASH
WORKDIR /var/www/html

# https://github.com/devthefuture-org/dockerfile-x/issues/6#issuecomment-2143844431
COPY flarum/20-composer-install.sh /docker-init.d/20-composer-install.sh
RUN <<'DASH' dash
    # we don't really run php in the nginx container
    sed -i 's/composer install$/& --ignore-platform-reqs/' /docker-init.d/20-composer-install.sh
DASH
