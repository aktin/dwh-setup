#!/usr/bin/env bash


. init.sh

# go to folder
cd $DATA_HOME/pm_db

$ANT_HOME/bin/ant -f change_build.xml drop_pm 2> $LOG_DIR/pm_del.err.log > $LOG_DIR/pm_del.log

