# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
# https://stackoverflow.com/questions/52444600/is-there-a-problem-with-using-php-zip-composer-warns-about-it
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo 7zip

cd /var/www/html || exit 1
# https://stackoverflow.com/questions/26356399/install-package-on-non-empty-folder-using-composer
rm -v *
chown www-data: .

# https://stackoverflow.com/questions/8633461/how-to-keep-environment-variables-when-using-sudo
sudo -Eu www-data composer --no-interaction create-project flarum/flarum:^1.8 .
