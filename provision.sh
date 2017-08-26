#!/bin/bash

php_config_file="/etc/php/7.0/apache2/php.ini"
xdebug_config_file="/etc/php/7.0/mods-available/xdebug.ini"
mysql_config_file="/etc/mysql/my.cnf"

export DEBIAN_FRONTEND=noninteractive

# Update the server
apt-get update
apt-get -y upgrade

if [[ -e /var/lock/vagrant-provision ]]; then
    exit;
fi

################################################################################
# Everything below this line should only need to be done once
# To re-run full provisioning, delete /var/lock/vagrant-provision and run
#
#    $ vagrant provision
#
# From the host machine
################################################################################

# Install basic tools
apt-get -y install build-essential binutils-doc git emacs24-nox zip

# Install Apache
apt-get -y install apache2
# And all the php things.
apt-get -y install php7.0 php7.0-curl php7.0-mysql php7.0-sqlite php-xdebug php7.0-gd \
 libapache2-mod-php7.0 php-xml php7.0-mbstring
# Also want Imagemagick for various helpful manipulations
apt-get -y install imagemagick php-imagick
# And our crossword site uses QPDF and I can't be bothered
# to make project-specific provisioning work here for just
# that one thing :D
apt-get -y install qpdf

sed -i "s/display_startup_errors = Off/display_startup_errors = On/g" ${php_config_file}
sed -i "s/display_errors = Off/display_errors = On/g" ${php_config_file}

cat << EOF > ${xdebug_config_file}
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_host=10.0.2.2
EOF

# Install MySQL
# MG The DEBIAN_FRONTENT=noninteractive flag above solved this problem for us, combined
# with the upgrade to Ubuntu 16.04 we now have a version of MySQL where if you're root,
# it won't bother asking you for a password, which is fine for my purposes.
#echo "mysql-server mysql-server/root_password password root" | sudo debconf-set-selections
#echo "mysql-server mysql-server/root_password_again password root" | sudo debconf-set-selections
apt-get -y install mysql-client mysql-server

sed -i "s/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" ${mysql_config_file}

# Allow root access from any host. We shouldn't need a user/password for MySQL if we're running as root.
echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION" | mysql
echo "GRANT PROXY ON ''@'' TO 'root'@'%' WITH GRANT OPTION" | mysql

# Overwrite default site config with one that allows htaccess override
cp /vagrant/vm_files/000-default.conf /etc/apache2/sites-available/000-default.conf

# Enable mod-rewrite in Apache
a2enmod rewrite

# Restart Services
service apache2 restart
service mysql restart

# Cleanup the default HTML file created by Apache, though if we've got our
# /var/www/html mapped through VirtualBox, it may not exist.
[ -e /var/www/html/index.html ] && rm /var/www/html/index.html

touch /var/lock/vagrant-provision
