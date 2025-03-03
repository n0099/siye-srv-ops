# syntax=docker/dockerfile:1
# https://github.com/just-containers/s6-overlay/blob/v3.2.0.2/README.md#quickstart
ARG S6_OVERLAY_VERSION=3.2.0.2 \
    S6_OVERLAY_NOARCH_SHA256=6dbcde158a3e78b9bb141d7bcb5ccb421e563523babbe2c64470e76f4fd02dae \
    S6_OVERLAY_ARCH_SHA256=59289456ab1761e277bd456a95e737c06b03ede99158beb24f12b165a904f478
ADD --checksum=sha256:${S6_OVERLAY_NOARCH_SHA256} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD --checksum=sha256:${S6_OVERLAY_ARCH_SHA256} https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN <<'ASH' ash -x
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ASH

COPY ./s6-rc.d /etc/s6-overlay/s6-rc.d/
VOLUME /s6-rc.extra.d
ENTRYPOINT ["ash", "-euxc", "[ -d /s6-rc.extra.d ] && cp -rv /s6-rc.extra.d/. /etc/s6-overlay/s6-rc.d; /init"]
