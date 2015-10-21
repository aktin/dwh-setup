#!/usr/bin/env bash

. init.sh


# install tables!
cd $DATA_HOME/Imdata/

$ANT_HOME/bin/ant -f data_build.xml create_imdata_tables_release_1-7 > $LOG_DIR/createproject8.log 2> $LOG_DIR/createproject8.err.log
	
$ANT_HOME/bin/ant -f data_build.xml db_imdata_load_data > $LOG_DIR/createproject10.log 2> $LOG_DIR/createproject10.err.log

