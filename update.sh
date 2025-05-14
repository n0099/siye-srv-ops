#!/bin/sh -eux
docker system prune -af
./run.sh pull
./run.sh build
./run.sh up -d --force-recreate
echo s8c mcbar v8c \
    | tr ' ' '\n' \
    | xargs -I{} sh -euxc 'docker compose --project-directory srv/{} exec -T s6 composer update'
