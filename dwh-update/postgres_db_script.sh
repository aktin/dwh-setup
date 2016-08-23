#!/usr/bin/env bash


psql -c "Delete from i2b2crcdata.observation_fact  where true;" i2b2
psql -c "Delete from i2b2crcdata.patient_dimension where true;" i2b2
psql -c "Delete from i2b2crcdata.patient_mapping where true;" i2b2
psql -c "Delete from i2b2crcdata.encounter_mapping where true" i2b2
