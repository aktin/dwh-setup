#!/bin/bash

# MY_PATH=$(pwd)
MY_PATH=/opt/i2b2Wizard
# export MY_PATH

OS_SCRIPT_IDENTIFIER="Ubuntu_14.04"
OS_SCRIPT_IDENTIFIER="Debian_7.8"
PRODUCT_SCRIPT_IDENTIFIER="i2b2_1.7.05"


cd $MY_PATH

. $MY_PATH/config/wizard.conf
. $MY_PATH/scripts/wizard_features.sh
. $MY_PATH/scripts/database_types/$DBTYPE.sh
. $MY_PATH/scripts/os_versions/$OS_SCRIPT_IDENTIFIER.sh
. $MY_PATH/scripts/product_versions/$PRODUCT_SCRIPT_IDENTIFIER.sh

autoDownloadPackages

echo --------------------------
echo AUTO INSTALL
echo --------------------------

autoInstallApps

# TODO: sicherstellen, dass /opt/ant.. da ist, ggf. geht obiger befehl nicht richtig


echo --------------------------
echo Load Demodata
echo --------------------------

# TODO test on clean system
loadBoston

echo --------------------------
echo Build Source
echo --------------------------

buildSource


startJBoss
