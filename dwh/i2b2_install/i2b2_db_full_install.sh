#!/usr/bin/env bash

# second

# install psql and create db

MY_PATH=/vagrant/

chmod +x $MY_PATH/i2b2_install/install.conf
. $MY_PATH/i2b2_install/install.conf

echo copy postgres driver to i2b2 folder
cp $PACKAGES/postgresql-9.2-1002.jdbc4.jar $DATA_HOME/

echo install postgresql
apt-get -q -y install aptitude postgresql > $LOG_DIR/autoPackageInstall_postgresql.log 2> $LOG_DIR/autoPackageInstall_postgresql.err.log

echo change psql user password
sudo -u postgres psql -c "alter user $DB_SYSUSER with password '$DB_SYSPASS';"  > $LOG_DIR/config_postgres1.log 2> $LOG_DIR/config_postgres1.err.log

echo create i2b2 db
sudo -u postgres createdb i2b2 > $LOG_DIR/config_postgres2.log 2> $LOG_DIR/config_postgres2.err.log

cd $DATA_HOME/db_user
echo create i2b2 users
$ANT_HOME/bin/ant -f init_build.xml create_POSTGRESQL_users 2> $LOG_DIR/create_db_user.err.log > $LOG_DIR/create_db_user.log

echo create db_hive
cd $DATA_HOME/db_hive/
./install.sh
echo update db_hive
./update.sh

echo create db_pm
cd $DATA_HOME/db_pm/
./install.sh

echo create db_work
cd $DATA_HOME/db_work/
./install.sh

echo create db_meta
cd $DATA_HOME/db_meta/
./install.sh

echo create db_crc
cd $DATA_HOME/db_crc/
./install.sh

cd $DATA_HOME/
