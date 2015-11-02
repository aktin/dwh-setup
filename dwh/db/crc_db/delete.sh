#!/usr/bin/env bash


. init.sh

# go to folder
cd $OTH_HOME/crc_db

$ANT_HOME/bin/ant -f change_build.xml drop_crc 2> $LOG_DIR/crc_boston_del.err.log > $LOG_DIR/crc_boston_del.log

