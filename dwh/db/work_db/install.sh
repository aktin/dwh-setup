#!/usr/bin/env bash

. init.sh

# install hive!
cd $DATA_HOME/Workdata/

$ANT_HOME/bin/ant -f data_build.xml create_workdata_tables_release_1-7 > $LOG_DIR/bostonload7.log 2> $LOG_DIR/bostonload7.err.log

# maybe don't need this later
$ANT_HOME/bin/ant -f data_build.xml db_workdata_load_data > $LOG_DIR/bostonload8.log 2> $LOG_DIR/bostonload8.err.log
