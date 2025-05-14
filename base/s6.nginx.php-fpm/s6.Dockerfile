# syntax=docker/dockerfile:1
# https://github.com/just-containers/s6-overlay/blob/v3.2.1.0/README.md#quickstart
# curl -L https://github.com/just-containers/s6-overlay/releases/download/v3.2.1.0/s6-overlay-{noarch,x86_64,symlinks-{no,}arch}.tar.xz.sha256
ARG S6_OVERLAY_VERSION=3.2.1.0 \
    S6_OVERLAY_NOARCH_SHA256=42e038a9a00fc0fef70bf0bc42f625a9c14f8ecdfe77d4ad93281edf717e10c5 \
    S6_OVERLAY_ARCH_SHA256=8bcbc2cada58426f976b159dcc4e06cbb1454d5f39252b3bb0c778ccf71c9435 \
    S6_OVERLAY_SYMLINKS_NOARCH_SHA256=5c0a28acc0aca6c86d90c9cd752361e0b69b0d57789064fbc8b066b2e21264d4 \
    S6_OVERLAY_SYMLINKS_ARCH_SHA256=c99a8c5747866aedf268067c2dadd755863044c4df76429314f5f0434200c9d5
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
