cd /var/www/html || exit 1
cp /mnt/flarum/* .
chown www-data: -R .
# https://github.com/composer/composer/issues/680
sudo -u www-data COMPOSER_HOME=/tmp/.composer composer install
# https://docs.flarum.org/extend/assets/
# https://docs.flarum.org/console/#assetspublish
sudo -u www-data php flarum assets:publish
