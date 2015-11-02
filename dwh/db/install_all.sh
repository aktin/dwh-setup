#!/usr/bin/env bash

. initparams.sh

echo create hive_db
./hive_db/install.sh

echo create pm_db
./pm_db/install.sh

echo create work_db
./work_db/install.sh

echo create meta_db
./meta_db/install.sh

echo create crc_db
./crc_db/install.sh
#todo add prints
