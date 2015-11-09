#!/usr/bin/env bash
# remove psql and db

. initparams.sh

cd $OTH_HOME/db_user

echo delete users
$ANT_HOME/bin/ant -f init_build.xml drop_POSTGRESQL_users 2> $LOG_DIR/remove_db_user.err.log > $LOG_DIR/remove_db_user.log

echo delete i2b2 db
sudo -u postgres dropdb i2b2 > $LOG_DIR/config_postgres2_drop.log 2> $LOG_DIR/config_postgres2_drop.err.log

echo uninstall postgresql
apt-get -q -y remove postgresql > $LOG_DIR/autoPackageInstall_postgresql_remove.log 2> $LOG_DIR/autoPackageInstall_postgresql_remove.err.log
