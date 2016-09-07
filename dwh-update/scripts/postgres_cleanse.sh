#!/usr/bin/env bash

#Löschen aller Fakten in der i2b2-Datenbank
su - postgres bash -c "psql -d i2b2 -c 'TRUNCATE i2b2crcdata.observation_fact, i2b2crcdata.patient_dimension, i2b2crcdata.patient_mapping, i2b2crcdata.encounter_mapping;'"