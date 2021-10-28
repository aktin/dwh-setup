#! /bin/bash
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>

set -euo pipefail # stop on errors

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

# create timestamp and log file
readonly LOGFILE=$(pwd)/deb_migration_$(date +%Y_%h_%d_%H%M).log

function check_root_privileges() {
   if [[ $EUID -ne 0 ]]; then
      echo -e "${RED}Dieses Script muss mit root-Rechten ausgeführt werden!${WHI}"
      exit 1
   fi
}

function update_root_certificates() {
   apt-get update && apt-get install -y ca-certificates
}

function include_aktin_repo() {
   wget -O - http://www.aktin.org/software/repo/org/apt/conf/aktin.gpg.key | sudo apt-key add -
   echo "deb http://www.aktin.org/software/repo/org/apt focal main" > /etc/apt/sources.list.d/aktin.list
}

function install_aktin_deb_packages() {
   apt-get install -y aktin-notaufnahme-i2b2
   apt-get install -y aktin-notaufnahme-dwh
   apt-get install -y aktin-notaufnahme-updateagent
}

function initialize_updateagent() {
   # run info.service
   nc -w 2 127.0.0.1 1002
   # run update.service
   nc -w 2 127.0.0.1 1003

   mkdir -p /var/lib/aktin/update
cat <<EOF > "/var/lib/aktin/update/result"
update.success=true
update.time=$(date)
EOF
}

function main() {
check_root_privileges
update_root_certificates
include_aktin_repo
apt-get update
install_aktin_deb_packages
initialize_updateagent
service wildfly restart
}

main | tee -a $LOGFILE
