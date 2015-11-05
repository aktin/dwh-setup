#!/usr/bin/env bash

. init.sh

# install hive!
cd $DATA_HOME/Pmdata/

$ANT_HOME/bin/ant -f data_build.xml create_pmdata_tables_release_1-7 > $LOG_DIR/pm_create_tab.err.log > $LOG_DIR/pm_create_tab.log

$ANT_HOME/bin/ant -f data_build.xml create_triggers_release_1-7 2> $LOG_DIR/pm_create_triggers.err.log > $LOG_DIR/pm_create_triggers.log

$ANT_HOME/bin/ant -f data_build.xml db_pmdata_load_data 2> $LOG_DIR/pm_load.err.log > $LOG_DIR/pm_load.log