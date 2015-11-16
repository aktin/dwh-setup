#!/usr/bin/env bash

. ../initparams.sh

# TODO move install & update together

# move the db properties to the data.
cp $OTH_HOME/meta_db/db.properties $DATA_HOME/Metadata/