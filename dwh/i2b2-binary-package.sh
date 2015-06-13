#!/bin/sh

# Wenn i2b2 erfolgreich kompiliert wurde, dann liegt das Ergebnis im JBOSS-Ordner
# Dieses Skript kopiert diese Dateien (für Installation ohne Kompilieren)
# TODO: ist noch nicht getestet

IBDIR=/var/tmp/i2b2-binaries
mkdir $IBDIR
JBDDIR=/opt/jboss-as-7.1.1.Final/standalone/deployments
cp $JBDDIR/*-ds.xml $IBDIR/
cp $JBDDIR/*-ds.xml.deployed $IBDIR/
cp $JBDDIR/postgresql* $IBDIR/
# actual binaries
cp -r $JBDDIR/i2b2.war $IBDIR/
cp $JBDDIR/i2b2.war.deployed $IBDIR/

# remove axis2 files from i2b2.war subdirectory
cd /var/tmp
unzip /vagrant/packages/axis2-1.6.2-war.zip axis2.war
cd $JBDIR/i2b2.war
zipinfo -s /var/tmp/axis2.war | grep '^-' | awk '{print $9}' | xargs -n1 rm -v
rm /var/tmp/axis2.war

# remove empty directories
find . -type d -empty -delete

# no need for oracle and mssql jdbc driver
rm WEB-INF/lib/ojdbc6.jar WEB-INF/lib/sqljdbc4.jar

tar cf /vagrant/packages/i2b2-war-bin.tar $IBDIR
