# vagrant init dhoppe/debian-7.8.0-amd64

vagrant box add deb/wheezy-amd64
or vagrant box add chef/debian-7.8
vagrant init deb/wheezy-amd64
vagrant up --provider virtualbox

# sudo bash
# login to box, cd /opt/i2b2Wizard, execute ./wizard.sh
# System Setup / Set Defaults
# System Setup / Download Required Packages
# System Setup / Install Required Packages
# Boston Demodata / Load Boston Demodata
# Build i2b2
# JBoss Control / Start JBoss

# edit /var/www/html/webclient/i2b2_config_data.js and replace ip by localhost

# for postgresql
sudo su - postgres
psql
# inside psql shell
#list databases
\l
\connect i2b2
# list namespaces
\dn
# list tables
\dp i2b2*.*


# list installed packages (not dependencies)
aptitude search '~i !~M' -F '%p' --disable-columns | sort -u > /vagrant/pre-wizard.txt

# set correct timezone
dpkg reconfigure tzdata


# TODO: replace package apache2 with apache2-mpm-prefork