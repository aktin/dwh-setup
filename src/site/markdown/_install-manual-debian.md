Manuelle Konfiguration von Debian
=================================

ACHTUNG: Alle nachfolgenden Schritte werden automatisch von
dem AKTIN-Installationsskript durchgeführt. Diese Anleitung
müssen Sie nur befolgen, wenn Sie das Installationsskript NICHT
verwenden wollen.

Java 8
------

Java 8 wird regulär erst im nächsten Debian-Release verfügbar sein.
Daher muss bei Debian 8 ein Backport-Mirror eingerichtet werden, um
auf die neueren Pakete zugreifen zu können:

```
echo 'deb http://http.debian.net/debian jessie-backports main' >> /etc/apt/sources.list
apt-get update
apt-get install -y openjdk-8-jre-headless
```

Weitere Pakete
--------------

Alle weiteren Pakete können direkt aus dem Repository verwendet werden:

```
apt-get install -y wget curl dos2unix unzip sed bc ant postgresql
apt-get install -y libapache2-mod-php5 php5-curl 
```
To be continued...
