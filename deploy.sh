#!/bin/bash
set -e

HOST_NAME=none.com
PRI_ENV_TYPE=dev
PHP_VERSION=8.1
USE_CERTBOT=yes
CERTBOT_USER_EMAIL=none@none.com

DB_EXISTING=no
DB_HOST=localhost
DB_SERVER_ROOT_USER=root
DB_SERVER_ROOT_PASSWORD=none
DB_NAME=dru_db_prod1
DB_USER=drupal_db
DB_PASSWORD=PassWord2023!

GIT_SSH_REPO=yes
GIT_EXISTING_KEY=yes
GIT_KEY_NAME=id_rsa
GIT_NAME=git@git
GIT_USER=git
GIT_EMAIL=none@none.com
EXISTING_WEBSITE=no

echo '';
echo '*******************************************'
echo '      Welcome to Drupal Deploy Script'
echo '*******************************************'
echo ''
echo "Press a key to start configuration"
echo ''
read -r REPLY

read -p "Enter host name [none.com]: " -r HOST_NAME
HOST_NAME=${HOST_NAME:-'none.com'}

read -p "Primary website environment type (prod,dev,staging) [dev]: " -r PRI_ENV_TYPE
PRI_ENV_TYPE=${PRI_ENV_TYPE:-'dev'}

read -p "Enter PHP version to use [$PHP_VERSION]: " -r PHP_VERSION
PHP_VERSION=${PHP_VERSION:-'8.1'}

read -p "Use Certbot to activate SSL ? (host name DNS must already be configured) [yes]: " -r USE_CERTBOT
USE_CERTBOT=${USE_CERTBOT:-'yes'}

if [[ "$USE_CERTBOT" == "yes" ]]; then
  read -p "Certbot email address [none@none.com]: " -r CERTBOT_USER_EMAIL
  CERTBOT_USER_EMAIL=${CERTBOT_USER_EMAIL:-'none@none.com'}
fi;

read -p "Is database already existing ? [no]: " -r DB_EXISTING
DB_EXISTING=${DB_EXISTING:-'no'}

if [[ "$DB_EXISTING" == "no" ]]; then
  read -p "Enter database host [localhost]: " -r DB_HOST
  DB_HOST=${DB_HOST:-'localhost'}

  read -p "Enter database server admin name [root]: " -r DB_SERVER_ROOT_USER
  DB_SERVER_ROOT_USER=${DB_SERVER_ROOT_USER:-'root'}

  read -p "Enter database server admin acount password ('none' keyword for local non secured server) [none]: " -r DB_SERVER_ROOT_PASSWORD
  DB_SERVER_ROOT_PASSWORD=${DB_SERVER_ROOT_PASSWORD:-'none'}

  read -p "Enter database name [dru_db_prod1]: " -r DB_NAME
  DB_NAME=${DB_NAME:-'dru_db_prod1'}

  read -p "Enter database user name [drupal_db]: " -r DB_USER
  DB_USER=${DB_USER:-'drupal_db'}

  read -p "Enter database password [PassWord2023!]: " -r DB_PASSWORD
  DB_PASSWORD=${DB_PASSWORD:-'PassWord2023!'}
fi;

read -p "Is Github repository already existing ? [yes]: " -r GIT_SSH_REPO
GIT_SSH_REPO=${GIT_SSH_REPO:-'yes'}

if [[ "$GIT_SSH_REPO" == "yes" ]]; then
  read -p "Is Github key already existing ? [yes]: " -r GIT_EXISTING_KEY
  GIT_EXISTING_KEY=${GIT_EXISTING_KEY:-'yes'}

  read -p "Enter key name [id_rsa]: " -r GIT_KEY_NAME
  GIT_KEY_NAME=${GIT_KEY_NAME:-'id_rsa'}

  read -p "Enter your GIT repository name [git@git]: " -r GIT_NAME
  GIT_NAME=${GIT_NAME:-'git@git'}

  read -p "Enter your GIT user name [git]: " -r GIT_USER
  GIT_USER=${GIT_USER:-'git'}

  read -p "Enter your GIT email [none@none.com]: " -r GIT_EMAIL
  GIT_EMAIL=${GIT_EMAIL:-'none@none.com'}
else
  echo '';
  echo 'It is recomended to create a repository to manage Drupal source code ;-)'
  echo 'You will already be able to do that after having installed everiting through this script';
  echo '';
fi;

read -p "Is website already existing ? (drives drush cex and drush dcdes) [no]: " -r EXISTING_WEBSITE
EXISTING_WEBSITE=${EXISTING_WEBSITE:-'no'}

echo ''
echo '*******************************************'
echo ''
echo "Press a key to start installation"
echo ''
read -r REPLY
echo ''

# Init
echo '# Init';
apt-get update && apt-get dist-upgrade -y && apt-get autoremove -y
apt install lsb-release apt-transport-https ca-certificates software-properties-common htop fail2ban apache2 -y

#oh my zsh to work faster
echo '#oh my zsh to work faster';
apt install zsh zip unzip git fonts-powerline -y
rm -Rf /root/.oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
chsh -s "$(which zsh)" "$(whoami)"
awk -i inplace ' { gsub("robbyrussell","agnoster");print } ' .zshrc
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi;
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
fi;
if [ ! -d ~/.oh-my-zsh/custom/plugins/command-time ]; then
  git clone https://github.com/popstas/zsh-command-time.git ~/.oh-my-zsh/custom/plugins/command-time
fi;

awk -i inplace ' { gsub("plugins=(git)","plugins=(git zsh-autosuggestions zsh-syntax-highlighting command-time)");print } ' .zshrc

# PHP packages installs
echo '# PHP packages installs';
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
sh -c 'echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
apt update
apt install php"$PHP_VERSION" php"$PHP_VERSION"-mysql certbot python3-certbot-apache php"$PHP_VERSION"-fpm php"$PHP_VERSION"-common php"$PHP_VERSION"-mysql php"$PHP_VERSION"-xml php"$PHP_VERSION"-xmlrpc php"$PHP_VERSION"-curl php"$PHP_VERSION"-gd php"$PHP_VERSION"-imagick php"$PHP_VERSION"-cli php"$PHP_VERSION"-dev php"$PHP_VERSION"-imap php"$PHP_VERSION"-mbstring php"$PHP_VERSION"-soap php"$PHP_VERSION"-zip php"$PHP_VERSION"-bcmath -y
apt autoremove -y
cd ~
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php'); if (hash_file('sha384', 'composer-setup.php') === '55ce33d7678c5a611085589f1f3ddf8b3c52d662cd01d4ba75c0ee0459970c2200a51f492d557530c71c15d8dba01eae') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
php composer-setup.php
php -r "unlink('composer-setup.php');"
mv composer.phar /usr/local/bin/composer
#a2dismod php$PHP_VERSION
a2dismod mpm_prefork
a2enmod mpm_event proxy_fcgi setenvif http2 rewrite
echo 'Installs done'

# Apache and Vhost configuration
echo '# Apache and Vhost configuration';
awk '/<Directory \/var\/www\/>/,/AllowOverride None/{sub("None", "All",$0)}{print}' /etc/apache2/apache2.conf > prov.txt
mv /etc/apache2/apache2.conf /etc/apache2/apache2.conf.bak
mv prov.txt /etc/apache2/apache2.conf
service php"$PHP_VERSION"-fpm restart
service apache2 restart
cd /var/www/html
mkdir -p "$HOST_NAME"
cd "$HOST_NAME"
wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/latest/download/drush.phar
chmod +x drush.phar
mv drush.phar /usr/local/bin/drush

# Github key
echo '# Github key';
cd ~/.ssh
if [[ "$GIT_EXISTING_KEY" == "no" ]]; then
  if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -b 1024 -t rsa -N "" -C "Github key" -f id_rsa
  fi;
fi;

if [ ! -f ./config ]; then
  if ! grep -q 'Host github.com' "./config"; then
    echo 'Host github.com' >> config
    echo 'HostName github.com' >> config
    echo "IdentityFile ~/.ssh/${GIT_KEY_NAME}" >> config
  fi;
fi;

echo ''
echo '---------------------------------------------'
echo ''
cat "$GIT_KEY_NAME".pub
echo ''
echo '---------------------------------------------'
echo 'add the key above to your github account'
echo 'if it has not been already done'
echo '---------------------------------------------'
echo ''
echo "Press a key to continue"
echo ''
read -r REPLY

cd /var/www/html/"$HOST_NAME"

# Git stuffs
echo '# Git stuffs';
if [ -d .git ]; then
  echo 'Git repository already initialized';
else
  git config --global user.email "$GIT_EMAIL"
  git config --global user.name "$GIT_USER"
  git init
  git remote add origin "$GIT_NAME"
  git branch -M main
fi;

# Installing or starting existing Drupal
echo '# Installing or starting existing Drupal';
if [[ "$EXISTING_WEBSITE" == "no" ]]; then
  cd /var/www/html/
  cd /var/www/html/"$HOST_NAME"
  rm -Rf *
  composer create-project drupal/recommended-project "$HOST_NAME" -n
  cd /var/www/html/"$HOST_NAME"
  composer require drupal/dotenv
  composer require drupal/drush
  cd /var/www/html/"$HOST_NAME"/web/sites/default
  cp default.settings.php settings.php

read -r -d '' VAR << EOM
<?php

error_reporting(E_ALL);
ini_set('display_errors', TRUE);
ini_set('display_startup_errors', TRUE);

\$conf['error_level'] = 2;
\$config['system.logging']['error_level'] = 'verbose';

use Symfony\Component\Dotenv\Dotenv;

(new Dotenv())->bootEnv(DRUPAL_ROOT . '/../.env');
EOM
awk -i inplace -v VAR="$VAR" ' { gsub("<?php",VAR);print } ' settings.php

read -r -d '' VAR << EOM
\$databases['default']['default'] = array (
  'database' => \$_ENV['DB_NAME'],
  'username' => \$_ENV['DB_USER'],
  'password' => \$_ENV['DB_PASSWORD'],
  'prefix' => \$_ENV['DB_PREFIX'] ?? '',
  'host' => \$_ENV['DB_HOST'],
  'port' => \$_ENV['DB_PORT'],
  'namespace' => 'Drupal\\mysql\\Driver\\Database\\mysql',
  'driver' => 'mysql',
  'autoload' => 'core/modules/mysql/src/Driver/Database/mysql/',
);


\$settings['config_sync_directory'] = 'config/sync';
global \$content_directories;
\$content_directories['sync'] = 'config/content';
\$settings['default_content_deploy_content_directory'] = 'config/content_deploy';
// Define trusted_host_patterns if defined in environment variable.
if (getenv('TRUSTED_HOST_PATTERN')) {
  \$settings['trusted_host_patterns'] = array(getenv('TRUSTED_HOST_PATTERN'));
}
EOM
echo "$VAR" >> settings.php
fi

cd /var/www/html/"$HOST_NAME"
git config --global --add safe.directory /var/www/html/"$HOST_NAME"
git add -A
git commit -am 'init drupal'
git push --set-upstream origin main

# DotEnv stuffs
echo '# DotEnv stuffs';
echo "APP_ENV=${PRI_ENV_TYPE}" >> .env
echo "" >> .env
echo "DB_NAME=${DB_NAME}" >> .env
echo "DB_USER=${DB_USER}" >> .env
echo "DB_PASSWORD=${DB_PASSWORD}" >> .env
echo "DB_PREFIX=" >> .env
echo "DB_HOST=${DB_HOST}" >> .env
echo "DB_PORT=3306" >> .env
echo "" >> .env
echo "# optional" >> .env
echo "TRUSTED_HOST_PATTERN='.*'" >> .env

# SQL stuffs
echo '# SQL stuffs';
if [[ "$DB_EXISTING" == "no" ]]; then
  RESULT_VARIABLE="$( mysql -e 'show databases;' )"
  if [[ "$RESULT_VARIABLE" == *"$DB_NAME"* ]]; then
    echo "Database exist"
  else
    if [[ "$DB_SERVER_ROOT_PASSWORD" == "none" ]]; then
      mysql -u "$DB_SERVER_ROOT_USER" -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    else
      mysql -u "$DB_SERVER_ROOT_USER" -p "$DB_SERVER_ROOT_PASSWORD" -h "$DB_HOST" -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    fi
  fi

  RESULT_VARIABLE="$(mysql -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$DB_USER')")"
  if [ "$RESULT_VARIABLE" -eq 0 ]; then
    if [[ "$DB_HOST" == "localhost" ]]; then
      mysql -e "CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';"
      mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';"
    else
      mysql -e "CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';"
      mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';"
    fi
  fi;
  mysql -e "FLUSH PRIVILEGES;"
fi;

# Installing or starting existing Drupal
echo '# Installing or starting existing Drupal';
if [[ "$EXISTING_WEBSITE" == "yes" ]]; then
  cd /var/www/html/"$HOST_NAME"/
  composer install -n
  composer update
  drush cr
  drush si --existing-config -y
  drush cr
  drush dcdi -y
  drush cr
  drush locale:update -y
  drush cr
  drush updb -y
  drush cr
fi

cd /var/www/html/
chown -R www-data:www-data "$HOST_NAME"
chmod 775 "$HOST_NAME" -R

# Managing Apache
echo '# Managing Apache';
awk -i inplace -v HOST_NAME="$HOST_NAME" ' { gsub("HOSTNAME_VAR",HOST_NAME);print } ' 001-drupal-vhost.txt
mv 001-drupal-vhost.txt /etc/apache2/sites-available/001-"$HOST_NAME".conf

echo "<VirtualHost *:80>" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >>  /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# The ServerName directive sets the request scheme, hostname and port that" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# the server uses to identify itself. This is used when creating" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# redirection URLs. In the context of virtual hosts, the ServerName" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# specifies what hostname must appear in the request's Host: header to" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# match this virtual host. For the default virtual host (this file) this" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# value is not decisive as it is used as a last resort host regardless." >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# However, you must set it for any further virtual host explicitly." >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "#ServerName www.example.com" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "ServerName ${HOSTNAME_VAR}" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "ServerAdmin webmaster@localhost" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "DocumentRoot /var/www/html/${HOSTNAME_VAR}/web" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# Available loglevels: trace8, ..., trace1, debug, info, notice, warn," >>  /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# error, crit, alert, emerg." >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# It is also possible to configure the loglevel for particular" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# modules, e.g." >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "#LogLevel info ssl:warn" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "ErrorLog ${APACHE_LOG_DIR}/error-${APACHE_LOG_DIR}.log" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "CustomLog ${APACHE_LOG_DIR}/access-${APACHE_LOG_DIR}.log combined" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "<FilesMatch \.php$>" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# For Apache version 2.4.10 and above, use SetHandler to run PHP as a fastCGI process server" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo SetHandler "proxy:unix:/run/php/php${PHP_VERSION}-fpm.sock|fcgi://localhost" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "</FilesMatch>" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# For most configuration files from conf-available/, which are" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# enabled or disabled at a global level, it is possible to" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# include a line for only one particular virtual host. For example the" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# following line enables the CGI configuration for this host only" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# after it has been globally disabled with 'a2disconf'." >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "#Include conf-available/serve-cgi-bin.conf" >>  /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "RewriteEngine on" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "RewriteCond %{SERVER_NAME} =${HOSTNAME_VAR}" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "</VirtualHost>" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf
echo "# vim: syntax=apache ts=4 sw=4 sts=4 sr noet" >> /etc/apache2/sites-available/001-"$HOST_NAME".conf

# Activation vhost
echo '# Activation vhost';
a2dissite 000-default.conf
a2ensite 001-"$HOST_NAME".conf
service apache2 restart
certbot run -n --apache --agree-tos -d "$HOST_NAME" -m "$CERTBOT_USER_EMAIL" --redirect

# Terminationg script
echo '# Terminationg script';
echo '-------------------------------'
echo 'Drupal admin unique access'
echo '-------------------------------'
cd /var/www/html/"$HOST_NAME"/
drush uli
echo '-------------------------------'
echo ''
echo Installation well terminated, Drupal ready.