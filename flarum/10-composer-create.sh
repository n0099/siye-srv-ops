# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
# https://stackoverflow.com/questions/52444600/is-there-a-problem-with-using-php-zip-composer-warns-about-it
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo 7zip
# https://github.com/composer/composer/issues/680
sudo -u www-data COMPOSER_HOME=/tmp/.composer composer create-project flarum/flarum:^1.8 /var/www/html
