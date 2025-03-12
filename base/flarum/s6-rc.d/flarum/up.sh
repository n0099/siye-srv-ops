#!/bin/ash -eux
cd /var/www
[ -f flarum ] && exit 0

# https://github.com/composer/composer/issues/680
# https://getcomposer.org/doc/03-cli.md#environment-variables
export COMPOSER_HOME=/tmp/.composer \
       COMPOSER_NO_DEV=1

# https://stackoverflow.com/questions/26356399/install-package-on-non-empty-folder-using-composer
su www-data -s /bin/ash -c 'composer create-project --no-interaction flarum/flarum:^1.8 fresh-flarum'
cd fresh-flarum
rm -rv public storage/sessions # mounted subdirs
find storage -mindepth 1 -maxdepth 1 -exec mv -v {} ../storage +
rm -rv storage
find -mindepth 1 -maxdepth 1 -exec mv -v {} .. +
cd ..
rm -rv fresh-flarum

# subdirs should be mounted as `services.*.volumes.volume.subpath` in `compose.yaml`
find /mnt/flarum -mindepth 1 -maxdepth 1 -type f -exec cp -v {} . +
chown www-data: -R .

su www-data -s /bin/ash -c 'composer install --no-interaction'

# https://docs.flarum.org/extend/assets/
# https://docs.flarum.org/console/#assetspublish
su www-data -s /bin/ash -c 'php flarum assets:publish'
