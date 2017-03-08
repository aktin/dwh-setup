#!/usr/bin/env bash

if psql -lqt | cut -d \| -f 1 | grep -qw aktin; then
    echo database aktin does already exist
    echo no action necessary
else
    echo database aktin does not exist
    createdb aktin
    psql -c "CREATE ROLE aktin with password 'aktin'" aktin
    psql -c "CREATE SCHEMA aktin AUTHORIZATION aktin" aktin
    psql -c "GRANT ALL ON SCHEMA aktin to aktin" aktin
    psql -c "ALTER ROLE aktin WITH LOGIN" aktin
fi