cd /vagrant/i2b2_install
pwd
echo install jboss
./install_jboss.sh > ../logs/install_jboss.log

echo install db
./i2b2_db_full_install.sh

cd /opt/jboss-as-7.1.1.Final/
pwd
ls standalone/deployments
ls bin
./bin/standalone.sh > /vagrant/logs/jboss_standalone_start.log