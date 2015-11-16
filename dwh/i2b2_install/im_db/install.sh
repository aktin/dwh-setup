#!/usr/bin/env bash

. init.sh


# install tables!
cd $DATA_HOME/Imdata/

$ANT_HOME/bin/ant -f data_build.xml create_imdata_tables_release_1-7 > $LOG_DIR/im_create.log 2> $LOG_DIR/im_create.err.log
	
$ANT_HOME/bin/ant -f data_build.xml db_imdata_load_data > $LOG_DIR/im_load.log 2> $LOG_DIR/im_load.err.log

