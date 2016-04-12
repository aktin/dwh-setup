#!/usr/bin/env bash

# Important: call with NO ROOT user!

install_root=/vagrant

BASE_DIR=$(pwd)
MY_PATH=$install_root

CDD_PATH=$BASE_DIR/aktin-cdd/

mkdir -p $CDD_PATH/local_extras

cd $CDD_PATH
cp -r $MY_PATH/profiles $CDD_PATH

cp $MY_PATH/packages/*.tar.gz $CDD_PATH/local_extras/aktin-installer.tar.gz

build-simple-cdd
build-simple-cdd --profiles aktin 
cp $CDD_PATH/images/debian-8.3-amd64-CD-1.iso /vagrant/
