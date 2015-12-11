#!/usr/bin/env bash

. ../install.conf

# go to folder
cd $DATA_HOME/db_hive

$ANT_HOME/bin/ant -f change_build.xml drop_hive 2> $LOG_DIR/hive_del.err.log > $LOG_DIR/hive_del.log
