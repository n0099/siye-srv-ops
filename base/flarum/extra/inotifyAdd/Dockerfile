# syntax=docker/dockerfile:1
FROM debian:bookworm-slim AS build

# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND=noninteractive \
    WEBP_VERSION
RUN <<'BASH' bash -euxo pipefail
    test -n "$WEBP_VERSION"
    apt-get update
    # https://github.com/webmproject/libwebp/blob/main/doc/building.md
    apt-get install -y curl gcc make auto{conf,make} libtool lib{jpeg,tiff,png}-dev
    mkdir /artifacts
    cd /artifacts
    curl -OJ https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-$WEBP_VERSION.tar.gz
    tar xf libwebp-$WEBP_VERSION.tar.gz
    cd libwebp-$WEBP_VERSION
    mkdir build
    cd build
    ../configure --enable-shared=no --disable-everything --enable-libwebpdemux # only build cwebp static binary
    make -j"$(nproc)"
    make install
BASH

FROM debian:bookworm-slim
COPY --from=build /usr/local/bin/cwebp /usr/local/bin/cwebp

RUN <<'DASH' dash -eux
    apt-get update
    apt-get install -y libjpeg62-turbo libpng16-16 libtiff6 inotify-tools
DASH

USER www-data
WORKDIR /var/www/html/inotifyAdd
ENTRYPOINT exec ./inotifyAdd.sh # using shell form as exec is a shell builtin
