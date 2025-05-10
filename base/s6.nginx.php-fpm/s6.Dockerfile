# syntax=docker/dockerfile:1
# https://github.com/just-containers/s6-overlay/blob/v3.2.0.2/README.md#quickstart
ARG S6_OVERLAY_VERSION=3.2.0.2 \
    S6_OVERLAY_NOARCH_SHA256=6dbcde158a3e78b9bb141d7bcb5ccb421e563523babbe2c64470e76f4fd02dae \
    S6_OVERLAY_ARCH_SHA256=59289456ab1761e277bd456a95e737c06b03ede99158beb24f12b165a904f478 \
    S6_OVERLAY_SYMLINKS_NOARCH_SHA256=da9552471ac9d324f07f22b546dfc36f0a76897d36a0f69952813feaec864a37 \
    S6_OVERLAY_SYMLINKS_ARCH_SHA256=a50ca9cc9c773bfcee362a96a0c68aeef1088d6873ff2968edcb5c840b89a19b
ADD --checksum=sha256:${S6_OVERLAY_NOARCH_SHA256} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD --checksum=sha256:${S6_OVERLAY_ARCH_SHA256} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
ADD --checksum=sha256:${S6_OVERLAY_SYMLINKS_NOARCH_SHA256} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
ADD --checksum=sha256:${S6_OVERLAY_SYMLINKS_ARCH_SHA256} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN <<'ASH' ash -x
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz
    rm -v /tmp/s6-overlay-*.tar.xz
ASH

COPY ./base/s6.nginx.php-fpm/s6-rc.d/ /etc/s6-overlay/s6-rc.d/
ENTRYPOINT ["ash", "-euxc", "[ -d /s6-rc.extra.d ] && find /s6-rc.extra.d -mindepth 2 -maxdepth 2 -exec cp -rv {} /etc/s6-overlay/s6-rc.d +; /init"]
