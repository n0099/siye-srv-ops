#!/bin/sh -eux
# https://stackoverflow.com/questions/67872347/whats-the-purpose-of-the-argument-at-the-end-of-bash-c-command-argument
time find srv -type f -name compose.yaml -exec sh -euxc \
    '/usr/bin/time -v docker compose --project-directory "$(dirname {})" "$@"' "$0" "$@" \;
