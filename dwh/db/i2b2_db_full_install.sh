#!/usr/bin/env bash

# install psql and create db

. initparams.sh

# db data
DB_SERVER=localhost
DB_PORT=5432
DB_SYSUSER=postgres
DB_SYSPASS=i2b2

cp $DATA_HOME/postgresql-9.2-1002.jdbc4.jar $OTH_HOME

echo install postgresql
apt-get -q -y install aptitude postgresql > $LOG_DIR/autoPackageInstall_postgresql.log 2> $LOG_DIR/autoPackageInstall_postgresql.err.log

echo change psql user password
sudo -u postgres psql -c "alter user $DB_SYSUSER with password '$DB_SYSPASS';"  > $LOG_DIR/config_postgres1.log 2> $LOG_DIR/config_postgres1.err.log

echo create i2b2 db
sudo -u postgres createdb i2b2 > $LOG_DIR/config_postgres2.log 2> $LOG_DIR/config_postgres2.err.log


#HIVE_SCHEMA=i2b2hive
#PM_SCHEMA=i2b2pm
#HIVE_PASS=i2b2hive
#PM_PASS=i2b2pm
#HIVE_ID=i2b2demo

cd $OTH_HOME/db_user
echo create i2b2 users
$ANT_HOME/bin/ant -f init_build.xml create_POSTGRESQL_users 2> $LOG_DIR/create_db_user.err.log > $LOG_DIR/create_db_user.log


echo create hive_db
./hive_db/install.sh
echo update hive_db
./hive_db/update.sh

echo create pm_db
./pm_db/install.sh

echo create work_db
./work_db/install.sh

echo create meta_db
./meta_db/install.sh

echo create crc_db
./crc_db/install.sh
#todo add prints
