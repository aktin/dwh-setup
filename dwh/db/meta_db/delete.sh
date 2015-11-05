#!/usr/bin/env bash


. init.sh

# go to folder
cd $OTH_HOME/meta_db

$ANT_HOME/bin/ant -f change_build.xml drop_meta 2> $LOG_DIR/meta_boston_del.err.log > $LOG_DIR/meta_boston_del.log

