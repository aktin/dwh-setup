#!/bin/bash
# Aktin Diagnose Script Version 1.1
# Neuste Änderungen: 
# *Javaversion auslesen
# *Version bei Start anzeigen
# *Check ob von Root ausgeführt
# *Version von Betriebssystem, postgres und java auslesen

ver=1.1
aktindir=/opt/wildfly-9.0.2.Final/standalone
dt=$(date '+%d-%m-%Y_%H-%M')

if [[ $EUID -ne 0 ]]; then
   echo "Dieses Script muss mit root Rechten ausgeführt werden!" 1>&2
   exit 1
fi

echo "Starte Diagnosescript Version $ver"

#spinner
spin()
{
  spinner="/|\\-/|\\-"
  while :
  do
    for i in `seq 0 7`
    do
      echo -n "${spinner:$i:1}"
      echo -en "\010"
      sleep 1
    done
  done
}

# Spinner starten
spin &

# Prozess ID von Spinner merken
SPIN_PID=$!

# Spinner bei jedem Signal killen
trap "kill -9 $SPIN_PID" `seq 0 15`

# Temp ordner erstellen wenn er nicht bereits existiert
tempdir=/tmp/aktindiagtemp
[ -d $tempdir ] || mkdir $tempdir

# Aktuelles Wildfly log kopieren
cp -R $aktindir/log/ $tempdir/log/

# ls -l von /deployments
ls -l $aktindir/deployments/ > $tempdir/deployments.txt

# Festplattenspeichernutzung df -h
df -h > $tempdir/diskspace.txt

# laufende Prozesse
printf "wildfly service status\n" > $tempdir/services.txt
service wildfly status >> $tempdir/services.txt
printf "wildfly ps\n" >> $tempdir/services.txt
ps -ef|grep wildfly|grep -v grep >> $tempdir/services.txt
printf "postgres service status\n" >> $tempdir/services.txt
service postgresql status >> $tempdir/services.txt
printf "postgres ps\n" >> $tempdir/services.txt
ps -ef|grep postgresql|grep -v grep >> $tempdir/services.txt
printf "java Prozesse\n" >> $tempdir/services.txt
ps -ef|grep java|grep -v grep >> $tempdir/services.txt

# versionen
printf "Betriebssystem\n" > $tempdir/version.txt
hostnamectl >> $tempdir/version.txt
printf "postgres version\n" >> $tempdir/version.txt
psql --version >> $tempdir/version.txt
printf "java Version\n" >> $tempdir/version.txt
java -version 2>> $tempdir/version.txt

# Arbeitsspeichernutzung (top)
top -b -n 1 > $tempdir/ram.txt

# Ordnerberechtigungen und Existenz
if [ -d /var/lib/aktin/ ]
	then
		printf "/var/lib/aktin/\n" > $tempdir/permissions.txt
		ls -ld /var/lib/aktin/ >> $tempdir/permissions.txt
	#reports
	if [ -d /var/lib/aktin/reports ]
	then
		printf "\n/var/lib/aktin/reports\n" >> $tempdir/permissions.txt
		ls -ld /var/lib/aktin/reports >> $tempdir/permissions.txt
	else
		printf "\nreports ordner existiert nicht\n" >> $tempdir/permissions.txt
	fi
	#report-temp
	if [ -d /var/tmp/report-temp ]
	then
		printf "\n/var/tmp/report-temp\n" >> $tempdir/permissions.txt
		ls -ld /var/tmp/report-temp >> $tempdir/permissions.txt
	else
		printf "\nreport-temp ordner existiert nicht\n" >> $tempdir/permissions.txt
	fi
	#report-archive
	if [ -d /var/lib/aktin/report-archive ]
	then
		printf "\n/var/lib/aktin/report-archive\n" >> $tempdir/permissions.txt
		ls -ld /var/lib/aktin/report-archive >> $tempdir/permissions.txt
	else
		printf "\nreport-archive ordner existiert nicht\n" >> $tempdir/permissions.txt
	fi
	#broker
	if [ -d /var/lib/aktin/broker ]
	then
		printf "\n/var/lib/aktin/broker\n" >> $tempdir/permissions.txt
		ls -ld /var/lib/aktin/broker >> $tempdir/permissions.txt
	else
		printf "\nbroker ordner existiert nicht\n" >> $tempdir/permissions.txt
	fi
	#broker-archive
	if [ -d /var/lib/aktin/broker-archive ]
	then
		printf "\n/var/lib/aktin/broker-archive\n" >> $tempdir/permissions.txt
		ls -ld /var/lib/aktin/broker-archive >> $tempdir/permissions.txt
	else
		printf "\nbroker-archive ordner existiert nicht\n" >> $tempdir/permissions.txt
	fi
else
	printf "aktin ordner existiert nicht\n" > permissions.txt
fi

# zippen
tar -czf $tempdir/aktindiag.tar.gz --absolute-names --warning=no-file-changed $tempdir/

# in den momentanen ordner ziehen
mv $tempdir/aktindiag.tar.gz ./

# schicken
#curl -u ondtmZILwmueOoS:aktindiag5918 -T $tempdir/aktindiag.tar.gz "https://cs.uol.de/public.php/webdav/aktindiag_$dt.tar.gz"

# aufräumen
rm -R $tempdir
echo "Die Datei aktindiag.tar.gz befindet sich nun in ihrem Ordner!"
kill -9 $SPIN_PID
