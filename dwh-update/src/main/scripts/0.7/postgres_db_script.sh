#!/usr/bin/env bash

createdb aktin
psql -c "CREATE ROLE aktin with password 'aktin'" aktin
psql -c "CREATE SCHEMA IF NOT EXISTS  aktin AUTHORIZATION aktin" aktin
psql -c "GRANT ALL ON SCHEMA aktin to aktin" aktin
psql -c "ALTER ROLE aktin WITH LOGIN" aktin

## psql: FATAL:  role "aktin" is not permitted to log in
## try: CREATE ROLE aktin with password 'aktin' LOGIN 
## or ALTER ROLE "aktin" WITH LOGIN;
