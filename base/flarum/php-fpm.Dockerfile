# syntax=devthefuture/dockerfile-x:1
INCLUDE php-fpm/Dockerfile

# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update # for `apt-get install` in `10-composer-create.sh`

# https://github.com/devthefuture-org/dockerfile-x/issues/6#issuecomment-2143844431
COPY flarum/10-composer-create.sh /docker-init.d/10-composer-create.sh
RUN <<'DASH' dash -eux
    . /docker-init.d/10-composer-create.sh
    rm /docker-init.d/10-composer-create.sh
DASH

COPY flarum/20-composer-install.sh /docker-init.d/20-composer-install.sh

# https://stackoverflow.com/questions/47615751/docker-compose-run-a-script-after-container-has-started/79333020#79333020
# https://stackoverflow.com/questions/1423352/source-all-files-in-a-directory-from-bash-profile/35726215#35726215
ENTRYPOINT ["bash", "-euxo", "pipefail", "-c", "source <(cat /docker-init.d/*.sh) && exec docker-php-entrypoint \"$@\"", "$@"]
# https://github.com/docker-library/php/blob/75a0c3c716c3d4f64800ccf098142ecd751197f8/8.3/bookworm/fpm/Dockerfile#L275
CMD ["php-fpm"]
