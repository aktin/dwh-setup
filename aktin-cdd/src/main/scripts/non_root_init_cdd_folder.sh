#!/usr/bin/env bash

# Important: call with NO ROOT user!

install_root=/vagrant

BASE_DIR=$(pwd)
MY_PATH=$install_root

CDD_PATH=$BASE_DIR/aktin-cdd/

mkdir -p $CDD_PATH/local_extras

cd $CDD_PATH
cp -r $MY_PATH/profiles $CDD_PATH

cp $MY_PATH/packages/dwh-install-*.tar.gz $CDD_PATH/local_extras/aktin-installer.tar.gz

# download manual packages
mkdir $MY_PATH/packages/packages 

wget https://cloudstorage.uni-oldenburg.de/index.php/s/67OY8vh6BSZq56w/download -O $MY_PATH/packages/packages/axis2-1.6.3-war.zip
wget https://cloudstorage.uni-oldenburg.de/index.php/s/0gRdGNsseGM5Gf9/download -O $MY_PATH/packages/packages/jboss-deployment-i2b2war-WEB-INF.zip
wget https://cloudstorage.uni-oldenburg.de/index.php/s/x1caQ5R0KUSwwVZ/download -O $MY_PATH/packages/packages/i2b2createdb-1706.zip
wget https://cloudstorage.uni-oldenburg.de/index.php/s/aWQcldqMgKlqxPC/download -O $MY_PATH/packages/packages/i2b2core-src-1706.zip
wget https://cloudstorage.uni-oldenburg.de/index.php/s/aaLhFTfemXBKsQA/download -O $MY_PATH/packages/packages/i2b2webclient-1706.zip
wget https://cloudstorage.uni-oldenburg.de/index.php/s/l8o6SM3Hueaxpen/download -O $MY_PATH/packages/packages/wildfly-9.0.2.Final.zip
wget https://cloudstorage.uni-oldenburg.de/index.php/s/PkC9jJiUeZ8ILBQ/download -O $MY_PATH/packages/packages/postgresql-9.2-1002.jdbc4.jar

tar czf $CDD_PATH/local_extras/packages.tar.gz $MY_PATH/packages/packages 

build-simple-cdd
build-simple-cdd --profiles aktin 
cp $CDD_PATH/images/debian-8.3-amd64-CD-1.iso /vagrant/debian-8.3-amd64-AKTIN-prepared-DVD-0.6.iso
