Automatische Konfiguration des AKTIN-Applikations-Server mit dem Installationsskript
===============================================

Unser Installationsskript wurde getestet mit Debian 8 und CentOS 7.
Wenn sie ein anderes System verwenden, müssen Sie die Skripte evtl. 
anpassen oder die enthaltenen Schritte manuell durchführen.

Mit dem Befehl 
```
uname -a
```
können Sie die Distribution des Linux-Systems herausfinden. 
In der Konsole sehen Sie dann ähnlich dem Folgenden: 
```
Linux debian-8 3.16.0-4-amd64 #1 SMP Debian 3.16.7-ckt20-1+deb8u1 (2015-12-14) x86_64 GNU/Linux
```

Um das Skript zu starten, brauchen Sie einen Konsolenzugang zum Server.
Wechseln Sie zunächst zum Benutzer `root` (z.B. via `su -`). Anschließend
können Sie unser Paket unter folgendem Link herunterladen:

- https://cloudstorage.uni-oldenburg.de/index.php/s/Vj6eXgKNEGrsT5L

z.B. mit 

```
# wget https://cloudstorage.uni-oldenburg.de/index.php/s/Vj6eXgKNEGrsT5L/download -O aktin.tar.gz
```
(evtl. mit Option `--no-check-certificate` bei Zertifikatfehlern).

Wenn das Paket heruntergeladen ist, kann es entpackt werden mit 
`tar xvzf aktin.tar.gz`. Die Dateien werden dann automatisch in 
den Ordner `aktin-dwh-snapshot` entpackt.

Die Installation benötigt Zugriff auf das Internet - speziell die jeweiligen 
Repositories und die Server der Universität Oldenburg, um die benötigten Pakete 
herunterzuladen.

Unter Debian 8, starten Sie nun das Skript `aktin-dwh-snapshot/install_debian.sh`.
Die Installation kann bis zu 20 Minuten dauern. 
Um die Konsolenausgaben umzuleiten, können Sie alternativ auch `aktin-dwh-snapshot/install_debian.sh > install-aktin-dwh.log` ausführen. Die Logausgaben finden Sie dann in der Datei `install-aktin-dwh.log`.

Für CentOS 7, starten Sie das Skript `aktin-dwh-snapshot/install_centos.sh`. 
SELinux wird in dem Prozess deaktiviert. Sollten Sie SELinux verwenden wollen 
müssen Sie es entsprechend manuell konfigurieren - oder die Skriptinhalte 
selektiv manuell ausführen.


Bevor die Funktionalität des Servers im Anschluss an das Installationsskript 
getestet werden benötigt der Server evtl. noch wenige Minuten um alle 
beteiligten Dienste zu starten und einzurichten.

Test des Data Warehouse
-----------------------
Wenn die Installation erfolgreich durchgeführt wurde, kann
anschließend per Web Browser auf das integrierte Data 
Warehouse zugegriffen werden. In der Adresszeile muss die 
entsprechende IP-Adresse / Servername angepasst werden:
`http://IHRSERVER/webclient/`


Test der Importschnittstelle
----------------------------
Die Importschnittstelle des Servers kann mit den Client-Programmen
aus dem Software-Paket (ZIP) des [Demo-Server](demo-server.html)
getestet werden:

```
java-client-fhir.bat http://IHRSERVER/aktin/cda/fhir/Binary examples\basismodul-beispiel-storyboard01.xml
```
