#!/usr/bin/env bash

CDATMPDIR=/var/tmp/cda-ontology

echo "update ontologies"
# unzip the sql jar 
unzip packages/cda-ontology-${project.dependencies[1].version}.jar -d $CDATMPDIR
chmod 777 -R $CDATMPDIR
touch update_sql.log
echo "update metadata " | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" | tee -a update_sql.log
echo "update crcdata " | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" | tee -a update_sql.log

# TODO remove CATMPDIR???