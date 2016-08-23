#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
install_root=$(dirname "$SCRIPT")/
su - postgres bash -c "$install_root/postgres_db_script.sh"
