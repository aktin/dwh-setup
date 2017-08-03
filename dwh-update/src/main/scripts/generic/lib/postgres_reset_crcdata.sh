#!/usr/bin/env bash

# service wildfly stop;
su - postgres bash -c "psql -d i2b2 -c 'TRUNCATE i2b2crcdata.observation_fact, i2b2crcdata.patient_dimension, i2b2crcdata.patient_mapping, i2b2crcdata.encounter_mapping, i2b2crcdata.visit_dimension;'"
# service wildfly start;