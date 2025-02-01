cd /var/www/html || exit 1

# subdirectories should be mounted as `services.*.volumes.volume.subpath` in `composer.yaml`
cp /mnt/flarum/* .
chown www-data: -R .

# https://stackoverflow.com/questions/8633461/how-to-keep-environment-variables-when-using-sudo
sudo -Eu www-data composer install --no-interaction

# https://docs.flarum.org/extend/assets/
# https://docs.flarum.org/console/#assetspublish
sudo -u www-data php flarum assets:publish
