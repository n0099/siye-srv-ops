# syntax=docker/dockerfile:1
FROM node:23-alpine AS build

RUN --mount=type=cache,target=/etc/apk/cache <<'ASH' ash -eux
    apk add --update-cache git
    git clone --depth 1 https://github.com/n0099/open-tbm
ASH

WORKDIR open-tbm/fe
COPY ./fe.env .env

# https://yarnpkg.com/configuration/yarnrc#globalFolder
RUN --mount=type=cache,target=/root/.yarn/berry <<'ASH' ash -eux
    corepack enable
    yarn install --immutable
    yarn build
ASH

FROM node:23-alpine

WORKDIR /artifacts
COPY --from=build open-tbm/fe/.output/ ./
RUN <<'ASH' ash -eux
    chown -R node: .
ASH

USER node
ENTRYPOINT ["node"]
CMD ["--heapsnapshot-near-heap-limit", "5", "--enable-source-maps", "server/index.mjs"]
