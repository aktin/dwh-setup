#!/usr/bin/env bash


. init.sh

# go to folder
cd $OTH_HOME/im_db

$ANT_HOME/bin/ant -f change_build.xml drop_im 2> $LOG_DIR/createproject8_del.err.log > $LOG_DIR/createproject8_del.log

