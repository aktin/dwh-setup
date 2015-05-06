#!/usr/bin/env bash

install_root=~/i2b2install
install_root=/vagrant

apt-get update
apt-get install -y wget curl subversion dos2unix dialog

cd /opt
# Download i2b2 Wizard
svn checkout --revision 295 http://community.i2b2.org/repos/i2b2/trunk/related/i2b2Wizard/trunk
mv trunk i2b2Wizard
cd i2b2Wizard
find . -name "*.sh" -type f -exec dos2unix {} \;
chmod +x wizard.sh

cp scripts/os_versions/Ubuntu_14.04.2_LTS.sh scripts/os_versions/Debian_7.8.sh

# apply patches
patch -p1 < $install_root/i2b2Wizard.patch

# copy sources
cp -v $install_root/packages/*.zip ./packages/

# additional dependencies for i2b2-wizard
apt-get install -y aptitude libcurl3 libapache2-mod-php5 php5-curl perl sed bc postgresql
# jre-headless not sufficient, need full jdk
#apt-get install -y openjdk-7-jre-headless
apt-get install -y openjdk-7-jdk

#apt-get -y dist-upgrade

# debian7.8 has ant package with required version 1.8.2, no need to compile ant from source

# enable remote access to postgres
/vagrant/postgres-remote-access.sh

# TODO: command line installation with i2b2-wizard
