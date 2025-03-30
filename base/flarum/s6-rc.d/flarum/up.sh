#!/bin/ash -eux
cd /var/www

# https://stackoverflow.com/questions/52291082/linux-bash-compare-hash-strings-without-setting-variables/52291204#52291204
[ "$(sha3sum -a 512 < composer.lock)" = "$(sha3sum -a 512 < /mnt/flarum/composer.lock)" ] && exit 0

# subdirs should be mounted as `services.*.volumes.volume.subpath` in `compose.yaml`
find /mnt/flarum -mindepth 1 -maxdepth 1 -type f -exec cp -v {} . +
chown www-data: -R .

su www-data -s /bin/ash -c 'composer install --no-interaction --no-dev'

# https://docs.flarum.org/extend/assets/
# https://docs.flarum.org/console/#assetspublish
su www-data -s /bin/ash -c 'php flarum assets:publish'
