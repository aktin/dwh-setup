#!/usr/bin/env bash

install_root=/vagrant

MY_PATH=$install_root
CDD_PATH=$MY_PATH/aktin-cdd


# install needed packages
echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
apt-get update
apt-get install -y less simple-cdd-profiles grub-pc grub-efi popularity-contest console-tools console-setup usbutils acpi acpid eject lvm2 mdadm cryptsetup reiserfsprogs jfsutils xfsprogs debootstrap busybox syslinux-common sy
slinux isolinux 
apt-get install -y openjdk-8-jre-headless sudo wget curl dos2unix unzip sed bc ant postgresql r-cran-xml r-cran-lattice libapache2-mod-php5 php5-curl openssh-server
apt-get install -y sudo wget curl dos2unix unzip sed bc simple-cdd 


echo $install_root


# modify simple cdd profiles
mv /usr/share/simple-cdd/tools/build/debian-cd /usr/share/simple-cdd/tools/build/debian-cd.old
cp $MY_PATH/tools/debian-cd /usr/share/simple-cdd/tools/build/debian-cd

mv /usr/share/simple-cdd/profiles/default.preseed /usr/share/simple-cdd/profiles/default.preseed.old
cp $MY_PATH/profiles/default.preseed /usr/share/simple-cdd/profiles/default.preseed 

# go to no root mode
dos2unix $MY_PATH/non_root_init_cdd_folder.sh
su - vagrant $MY_PATH/non_root_init_cdd_folder.sh

