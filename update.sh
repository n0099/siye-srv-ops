#!/bin/sh -eux
./run.sh pull
./run.sh build --no-cache
./run.sh up -d --force-recreate
echo s8c mcbar v8c \
    | tr ' ' '\n' \
    | xargs -I{} sh -euxc 'docker compose --project-directory srv/{} exec -T s6 composer update'
docker system df -v
docker system prune -af
docker system df -v
