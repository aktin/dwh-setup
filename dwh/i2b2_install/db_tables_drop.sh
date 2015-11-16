#!/usr/bin/env bash

. initparams.sh

echo delete hive_db
./hive_db/delete.sh

echo delete pm_db
./pm_db/delete.sh

echo delete work_db
./work_db/delete.sh

echo delete meta_db
./meta_db/delete.sh

echo delete crc_db
./crc_db/delete.sh
