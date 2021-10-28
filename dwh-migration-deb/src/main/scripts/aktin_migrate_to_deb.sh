#! /bin/bash
# maintainer: Alexander Kombeiz <akombeiz@ukaachen.de>

set -euo pipefail # stop on errors

# colors for console output
readonly WHI=${color_white}
readonly RED=${color_red}
readonly ORA=${color_orange}
readonly YEL=${color_yellow}
readonly GRE=${color_green}

CURRENT_DATE=$(date +%Y_%H_%d_%H%M)

function check_root_privileges() {
   if [[ $EUID -ne 0 ]]; then
      echo -e "${RED}Dieses Script muss mit root-Rechten ausgeführt werden!${WHI}"
      exit 1
   fi
}

function stop_wildfly() {
   if systemctl is-active --quiet wildfly; then
	   service wildfly stop
   fi
}

function backup_aktin_properties() {
   mkdir -p /etc/aktin
   PATH_PROPERTIES=/opt/wildfly/standalone/configuration/aktin.properties
   if [[ -f $PATH_PROPERTIES ]]; then
      cp -f $PATH_PROPERTIES /etc/aktin/backup_$CURRENT_DATE.properties;
   fi
}

function remove_wildfly_services() {
   rm -rf /etc/wildfly
   rm -rf /etc/default/wildfly
   rm -f /etc/init.d/wildfly
   rm -f /lib/systemd/system/wildfly.service
   systemctl daemon-reload
}

function remove_wildfly() {
   rm -f /opt/wildfly
   rm -rf /opt/wildfly-*
}

function remove_apache2_webclient() {
   rm -rf /var/www/html/webclient
}

function remove_apache2_proxy_conf() {
   a2dismod proxy_http >/dev/null 2>&1 || true
   a2disconf aktin-j2ee-reverse-proxy >/dev/null 2>&1 || true
   service apache2 restart
   rm -f /etc/apache2/conf-available/aktin-j2ee-reverse-proxy.conf
}

function remove_old_import_scripts() {
   rm -f /var/lib/aktin/import-scripts/*
}

function update_root_certificates() {
   apt-get update && apt-get install -y ca-certificates
}

function include_aktin_repo() {
   wget -O - http://www.aktin.org/software/repo/org/apt/conf/aktin.gpg.key | sudo apt-key add -
   echo "deb http://www.aktin.org/software/repo/org/apt focal main" > /etc/apt/sources.list.d/aktin.list
}

function install_aktin_deb_packages() {
   if ! systemctl is-active --quiet postgresql; then
	   service postgresql start
   fi
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

function apply_aktin_properties_backup() {
   PATH_PROPERTIES=/etc/aktin/aktin.properties
   # get newest backup of aktin.properties
   # if there are no backups, skip this function
   if [[ $(ls /etc/aktin/ | grep -c "backup_*") > 0 ]]; then
      BACKUP_NEWEST=$(ls -t /etc/aktin/backup_* | head -1);
   else
      chown wildfly:wildfly $PATH_PROPERTIES
      return 1
   fi

   # iterate through all rows in backup,
   # line start until '=' -> KEY
   # '=' until line end -> VALUE
   # overwrite value in aktin.properties with backup if found
   while read -r line_backup; do
      if [[ ! $line_backup = \#* && ! -z $line_backup ]]; then
         KEY=${line_backup%=*}
         VALUE=${line_backup#*=}
         while read -r line_org; do
               if [[ ! $line_org = \#* && ! -z $line_org ]]; then
                  if [[ ${line_org%=*} == $KEY ]]; then
                     sed -i "s|${KEY}=.*|${KEY}=${VALUE}|" $PATH_PROPERTIES
                     break
                  fi
               fi
         done < $PATH_PROPERTIES
      fi
   done < $BACKUP_NEWEST
   chown wildfly:wildfly $PATH_PROPERTIES
}

function update_script_keys_of_imported_files() {
# change script key of all files uploaded to p21
   for folder in /var/lib/aktin/import/*; do
      sed -i "s|script=.*|script=p21|" $folder/properties
   done
}

function main() {
check_root_privileges
stop_wildfly
backup_aktin_properties
remove_wildfly_services
remove_wildfly
remove_apache2_webclient
remove_apache2_proxy_conf
remove_old_import_scripts
update_root_certificates
include_aktin_repo
apt-get update
install_aktin_deb_packages
initialize_updateagent
apply_aktin_properties_backup
update_script_keys_of_imported_files
service wildfly restart
}

main
