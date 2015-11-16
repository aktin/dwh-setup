#!/usr/bin/env bash

. init.sh

# go to folder
cd $OTH_HOME/hive_db

$ANT_HOME/bin/ant -f change_build.xml update_hive 2> $LOG_DIR/hive_update.err.log > $LOG_DIR/hive_update.log
