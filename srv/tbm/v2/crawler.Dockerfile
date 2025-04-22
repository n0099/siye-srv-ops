# syntax=docker/dockerfile:1
FROM mcr.microsoft.com/dotnet/sdk:9.0-alpine AS build

RUN <<'ASH' ash -eux
    git clone --recurse-submodules --depth 1 https://github.com/n0099/open-tbm
    cd open-tbm/c#/crawler
    dotnet publish -p:PublishProfile=FolderProfile -r linux-musl-x64
ASH

FROM mcr.microsoft.com/dotnet/runtime:9.0-alpine

COPY --from=build open-tbm/c#/crawler/publish /artifacts
WORKDIR /artifacts

RUN <<'ASH' ash -eux
    chown -R app: .
ASH

# https://github.com/dotnet/dotnet-docker/issues/4451
USER app
ENTRYPOINT ["./tbm.Crawler"]
