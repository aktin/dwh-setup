#!/usr/bin/env bash
# remove psql and db

. initparams.sh

# db data
DB_SERVER=localhost
DB_PORT=5432
DB_SYSUSER=postgres
DB_SYSPASS=i2b2

cd $OTH_HOME/db_user

echo delete i2b2 db
sudo -u postgres dropdb i2b2 > $LOG_DIR/config_postgres2_drop.log 2> $LOG_DIR/config_postgres2_drop.err.log

echo delete users
$ANT_HOME/bin/ant -f init_build.xml drop_POSTGRESQL_users 2> $LOG_DIR/create_db_user.err.log > $LOG_DIR/create_db_user.log

echo uninstall postgresql
#apt-get -q -y remove aptitude postgresql > $LOG_DIR/autoPackageInstall_postgresql.log 2> $LOG_DIR/autoPackageInstall_postgresql.err.log
