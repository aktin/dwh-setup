#!/usr/bin/env bash

# second

# install psql and create db

MY_PATH=/vagrant/

chmod +x $MY_PATH/i2b2_install/install.conf
. $MY_PATH/i2b2_install/install.conf

echo copy postgres driver to i2b2 folder
cp $PACPACKAGES/postgresql-9.2-1002.jdbc4.jar $DATA_HOME/

echo install postgresql
apt-get -q -y install aptitude postgresql > $LOG_DIR/autoPackageInstall_postgresql.log 2> $LOG_DIR/autoPackageInstall_postgresql.err.log

echo change psql user password
sudo -u postgres psql -c "alter user $DB_SYSUSER with password '$DB_SYSPASS';"  > $LOG_DIR/config_postgres1.log 2> $LOG_DIR/config_postgres1.err.log

echo create i2b2 db
sudo -u postgres createdb i2b2 > $LOG_DIR/config_postgres2.log 2> $LOG_DIR/config_postgres2.err.log

cd $DATA_HOME/db_user
echo create i2b2 users
$ANT_HOME/bin/ant -f init_build.xml create_POSTGRESQL_users 2> $LOG_DIR/create_db_user.err.log > $LOG_DIR/create_db_user.log

echo create hive_db
cd $DATA_HOME/hive_db/
./install.sh
echo update hive_db
./update.sh

echo create pm_db
cd $DATA_HOME/pm_db/
./install.sh

echo create work_db
cd $DATA_HOME/work_db/
./install.sh

echo create meta_db
cd $DATA_HOME/meta_db/
./install.sh

echo create crc_db
cd $DATA_HOME/crc_db/
./install.sh

cd $DATA_HOME/
