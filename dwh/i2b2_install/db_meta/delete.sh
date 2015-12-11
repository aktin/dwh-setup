#!/usr/bin/env bash

. ../install.conf

# go to folder
cd $DATA_HOME/db_meta

$ANT_HOME/bin/ant -f change_build.xml drop_meta 2> $LOG_DIR/meta_boston_del.err.log > $LOG_DIR/meta_boston_del.log

