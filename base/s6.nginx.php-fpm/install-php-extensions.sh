#!/bin/ash -eux

# https://unix.stackexchange.com/questions/599771/prepend-and-append-a-string-to-each-element-of-in-shell/599776#599776
for i do
    set -- "$@" "php83-${i}"
    shift
done
apk add --no-cache "$@"
