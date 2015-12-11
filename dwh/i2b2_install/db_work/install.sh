#!/usr/bin/env bash

. ../install.conf

# install work!
cp db.properties $I2B2_DATA/Workdata/

cd $I2B2_DATA/Workdata/

$ANT_HOME/bin/ant -f data_build.xml create_workdata_tables_release_1-7 > $LOG_DIR/wrok_boston_create.log 2> $LOG_DIR/wrok_boston_create.err.log

# maybe don't need this later
$ANT_HOME/bin/ant -f data_build.xml db_workdata_load_data > $LOG_DIR/wrok_boston_load.log 2> $LOG_DIR/wrok_boston_load.err.log
