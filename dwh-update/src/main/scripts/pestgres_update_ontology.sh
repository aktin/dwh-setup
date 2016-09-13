#!/usr/bin/env bash

CDATMPDIR=/var/tmp/cda-ontology

echo "update ontologies"
# unzip the sql jar 
unzip cda-ontology-0.6-SNAPSHOT.jar -d $CDATMPDIR
chmod 777 -R $CDATMPDIR
touch update_sql.log
echo "update metadata " >> update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" >> update_sql.log
echo "update crcdata " >> update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" >> update_sql.log
