#!/usr/bin/env bash

. init.sh

# install hive!
cd $DATA_HOME/Hivedata/

$ANT_HOME/bin/ant -f data_build.xml create_hivedata_tables_release_1-7 2> $LOG_DIR/hive_create_tab.err.log > $LOG_DIR/hive_create_tab.log

$ANT_HOME/bin/ant -f data_build.xml db_hivedata_load_data 2> $LOG_DIR/hive_load.err.log > $LOG_DIR/hive_load.log
