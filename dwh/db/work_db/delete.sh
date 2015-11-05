#!/usr/bin/env bash


. init.sh

# go to folder
cd $OTH_HOME/work_db

$ANT_HOME/bin/ant -f change_build.xml drop_work 2> $LOG_DIR/wrok_boston_del.err.log > $LOG_DIR/wrok_boston_del.log

