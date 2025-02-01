# syntax=docker/dockerfile:1
ARG CRON_BASE_IMAGE
# https://github.com/devthefuture-org/dockerfile-x/issues/11
FROM $CRON_BASE_IMAGE

# https://github.com/aptible/supercronic/releases/tag/v0.2.33
ARG SUPERCRONIC_URL=https://github.com/aptible/supercronic/releases/download/v0.2.33/supercronic-linux-amd64 \
    SUPERCRONIC_SHA1SUM=71b0d58cc53f6bd72cf2f293e09e294b79c666d8 \
    SUPERCRONIC=supercronic-linux-amd64
RUN <<'DASH' dash -eux
    curl -fsSLO "$SUPERCRONIC_URL"
    echo "${SUPERCRONIC_SHA1SUM}  ${SUPERCRONIC}" | sha1sum -c -
    chmod +x "$SUPERCRONIC"
    mv "$SUPERCRONIC" "/usr/local/bin/${SUPERCRONIC}"
    ln -s "/usr/local/bin/${SUPERCRONIC}" /usr/local/bin/supercronic
DASH

# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND=noninteractive \
    CRONTAB
RUN <<'DASH' dash -eux
    test -n "$CRONTAB"
    echo "$CRONTAB" > /etc/crontab

    apt-get update
    apt-get install -y sudo
DASH

# https://stackoverflow.com/questions/47615751/docker-compose-run-a-script-after-container-has-started/79333020#79333020
# https://stackoverflow.com/questions/1423352/source-all-files-in-a-directory-from-bash-profile/35726215#35726215
# to reset possible entrypoint in image $CRON_BASE_IMAGE and run possible `/docker-init.d` from base image
ENTRYPOINT ["bash", "-euxo", "pipefail", "-c", "source <(cat /docker-init.d/*.sh) && exec \"$@\"", "$@"]
# not using `USER www-data` to run `/docker-init.d` with root
CMD ["sudo", "-u", "www-data", "supercronic", "/etc/crontab"]
