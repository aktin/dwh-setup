#!/usr/bin/env bash

createdb aktin
psql -c "CREATE ROLE aktin with password 'aktin'" aktin
psql -c "CREATE SCHEMA IF NOT EXISTS  aktin AUTHORIZATION aktin" aktin
psql -c "GRANT ALL ON SCHEMA aktin to aktin" aktin

