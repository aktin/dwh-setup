#!/usr/bin/env bash

. init.sh

# install hive!
cd $DATA_HOME/Pmdata/

$ANT_HOME/bin/ant -f data_build.xml create_pmdata_tables_release_1-7 > $LOG_DIR/loadhive4.err.log > $LOG_DIR/loadhive4.log

$ANT_HOME/bin/ant -f data_build.xml create_triggers_release_1-7 2> $LOG_DIR/loadhive5.err.log > $LOG_DIR/loadhive5.log

$ANT_HOME/bin/ant -f data_build.xml db_pmdata_load_data 2> $LOG_DIR/loadhive6.err.log > $LOG_DIR/loadhive6.log