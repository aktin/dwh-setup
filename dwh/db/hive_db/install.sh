#!/usr/bin/env bash

. init.sh

# install hive!
cd $DATA_HOME/Hivedata/

$ANT_HOME/bin/ant -f data_build.xml create_hivedata_tables_release_1-7 2> $LOG_DIR/loadhive2.err.log > $LOG_DIR/loadhive2.log

$ANT_HOME/bin/ant -f data_build.xml db_hivedata_load_data 2> $LOG_DIR/loadhive3.err.log > $LOG_DIR/loadhive3.log
