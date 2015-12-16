#!/usr/bin/env bash

install_root=~/i2b2install
install_root=/vagrant

apt-get update
apt-get install -y wget curl subversion dos2unix dialog

: <<'END'
# i2b2Wizard
cd /opt
# Download i2b2 Wizard
# TODO include current revision number in checkout
svn checkout http://community.i2b2.org/repos/i2b2/trunk/related/i2b2Wizard/trunk --revision 343
mv trunk i2b2Wizard
cd i2b2Wizard

# remove svn directories
 find . -name .svn -type d -print0 | xargs -0 -n1 rm -rf

# convert scripts
 find . -name "*.sh" -type f -exec dos2unix {} \;
 chmod +x wizard.sh

# link packages
 rmdir packages
 ln -s $install_root/packages .
END

ifconfig

# create postgres databases for i2b2
# cd $install_root
dos2unix /vagrant/autoinstall.sh

LOG_DIR=/vagrant/logs
if [ ! -d "$LOG_DIR" ]; then 
    mkdir $LOG_DIR
fi

/vagrant/autoinstall.sh > $LOG_DIR/autoinstall.log 2> $LOG_DIR/autoinstall.err.log
