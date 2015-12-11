#!/usr/bin/env bash


. ../install.conf

# go to folder
cd $DATA_HOME/db_pm

$ANT_HOME/bin/ant -f change_build.xml drop_pm 2> $LOG_DIR/pm_del.err.log > $LOG_DIR/pm_del.log

