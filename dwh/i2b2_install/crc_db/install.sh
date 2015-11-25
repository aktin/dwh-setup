#!/usr/bin/env bash

. ../install.conf

# install tables!
cp $DATA_HOME/crc_db/db.properties $I2B2_DATA/Crcdata/
cd $I2B2_DATA/Crcdata/

echo create crc tables
$ANT_HOME/bin/ant -f data_build.xml create_crcdata_tables_release_1-7 > $LOG_DIR/demo_crc_boston_create_tab.log 2> $LOG_DIR/demo_crc_boston_create_tab.err.log

echo create procedures 
$ANT_HOME/bin/ant -f data_build.xml create_procedures_release_1-7 > $LOG_DIR/demo_crc_boston_create_pro.log 2> $LOG_DIR/demo_crc_boston_create_pro.err.log

#maybe dont need this?
echo load demodata
$ANT_HOME/bin/ant -f data_build.xml db_demodata_load_data > $LOG_DIR/demo_crc_boston_load.log 2> $LOG_DIR/demo_crc_boston_load.err.log