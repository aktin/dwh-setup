#!/usr/bin/env bash

. init.sh

# install tables!
cd $DATA_HOME/Crcdata/

echo create crc tables
$ANT_HOME/bin/ant -f data_build.xml create_crcdata_tables_release_1-7 > $LOG_DIR/bostonload4.log 2> $LOG_DIR/bostonload4.err.log

echo create procedures 
$ANT_HOME/bin/ant -f data_build.xml create_procedures_release_1-7 > $LOG_DIR/bostonload5.log 2> $LOG_DIR/bostonload5.err.log

echo load demodata
$ANT_HOME/bin/ant -f data_build.xml db_demodata_load_data > $LOG_DIR/bostonload6.log 2> $LOG_DIR/bostonload6.err.log