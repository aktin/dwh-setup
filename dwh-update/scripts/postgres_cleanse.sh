#!/usr/bin/env bash

# POSTGRE_SQL=/var/tmp/aktin_tmp_postgres_cleanse_crc_db.sql

# echo " " > $POSTGRE_SQL
# echo "TRUNCATE i2b2crcdata.observation_fact, i2b2crcdata.patient_dimension, i2b2crcdata.patient_mapping, i2b2crcdata.encounter_mapping;" >> $POSTGRE_SQL
# echo "" > $POSTGRE_SQL
# su - postgres bash -c "psql -d i2b2 -f $POSTGRE_SQL"
su - postgres bash -c "psql -d i2b2 -c 'TRUNCATE i2b2crcdata.observation_fact, i2b2crcdata.patient_dimension, i2b2crcdata.patient_mapping, i2b2crcdata.encounter_mapping;'"

# rm $POSTGRE_SQL
