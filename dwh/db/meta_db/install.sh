#!/usr/bin/env bash

. init.sh

# install tables!
cd $DATA_HOME/Metadata/

echo create meta tables
$ANT_HOME/bin/ant -f data_build.xml create_metadata_tables_release_1-7 > $LOG_DIR/meta_boston_create.log 2> $LOG_DIR/meta_boston_create.err.log
	
# comment this out to avoid load boston data
echo load meta demo data
$ANT_HOME/bin/ant -f data_build.xml db_metadata_load_data > $LOG_DIR/meta_boston_load.log 2> $LOG_DIR/meta_boston_load.log
