#!/usr/bin/env bash

WILDFLY_HOME=/opt/wildfly-9.0.2.Final
install_root=$(pwd)

echo "create AKTIN database with postgres user"
su - postgres bash -c "$install_root/postgres_db_script.sh"

echo "create AKTIN datasource in jboss"
$WILDFLY_HOME/bin/jboss-cli.sh  --connect controller=127.0.0.1 --file=create_aktin_datassource.cli

# data-source add --name=AktinDS --jndi-name=java:jboss/datasources/AktinDS --driver-name=postgresql-9.2-1002.jdbc4.jar --connection-url=jdbc:postgresql://localhost:5432/aktin --user-name=aktin --password=aktin

# jboss-cli.sh --connect --commands="ls deployment"
# ./jboss-cli.sh --connect controller=127.0.0.1

# /subsystem=datasources:read-resource

# /subsystem=datasources:installed-drivers-list