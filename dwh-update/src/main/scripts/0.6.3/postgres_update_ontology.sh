#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")

CDATMPDIR=/var/tmp/cda-ontology

mkdir $CDATMPDIR

touch update_sql.log

echo "update ontologies to ${org.aktin:cda-ontology:jar.version}" 2>&1 | tee -a update_sql.log
# unzip the sql jar 
unzip $install_root/packages/cda-ontology-${org.aktin:cda-ontology:jar.version}.jar -d $CDATMPDIR
chmod 777 -R $CDATMPDIR

# call sql script files. no console output since spamming
echo "update metadata " 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/meta.sql" 2>&1 >> update_sql.log
echo "update crcdata " 2>&1 | tee -a update_sql.log
su - postgres bash -c "psql -d i2b2 -f $CDATMPDIR/sql/data.sql" 2>&1 >> update_sql.log

# remove temp directory
rm -r $CDATMPDIR