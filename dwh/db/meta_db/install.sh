#!/usr/bin/env bash

. init.sh

# install tables!
cd $DATA_HOME/Metadata/

$ANT_HOME/bin/ant -f data_build.xml create_metadata_tables_release_1-7 > $LOG_DIR/createproject2.log 2> $LOG_DIR/createproject2.err.log
	
