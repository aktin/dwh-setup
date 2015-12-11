#!/usr/bin/env bash

. ../install.conf

# go to folder
cd $DATA_HOME/db_crc

$ANT_HOME/bin/ant -f change_build.xml drop_crc 2> $LOG_DIR/demo_crc_boston_del.err.log > $LOG_DIR/demo_crc_boston_del.log

