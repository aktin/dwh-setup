#!/usr/bin/env bash


. init.sh

# go to folder
cd $OTH_HOME/pm_db

$ANT_HOME/bin/ant -f change_build.xml drop_pm 2> $LOG_DIR/loadhive_del1.err.log > $LOG_DIR/loadhive_del1.log

