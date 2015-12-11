#!/usr/bin/env bash

. ../install.conf

# go to folder
cd $DATA_HOME/db_work

$ANT_HOME/bin/ant -f change_build.xml drop_work 2> $LOG_DIR/wrok_boston_del.err.log > $LOG_DIR/wrok_boston_del.log

