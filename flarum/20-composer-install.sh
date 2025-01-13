cp /mnt/flarum/* /var/www/html
chown www-data: -R /var/www/html
cd /var/www/html
sudo -u www-data composer install
