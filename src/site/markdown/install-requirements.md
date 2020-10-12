Voraussetzungen für eine manuelle Installation des Betriebssystems für den AKTIN-Applikationsserver
================================================================

Grundsätzlich ist die Software auf allen Linux-Systemen verwendbar.

Für Ubuntu 20.04 LTS werden Skripte für eine automatische Installation und Konfiguration bereitgestellt. Es wird an dieser Stelle explizit darauf verwiesen, dass das Installationsskript aktuell nur mit Ubuntu 20.04 LTS und Ubuntu 18.04 LTS getestet wurde. Für eine Neuinstallation wird Ubuntu Server 20.04 LTS empfohlen. Dabei handelt es sich um eine minimalistische Ubuntu-Version optimiert für das Betreiben von Servern. Als Installationsmedium empfehlen wir, das offizielle [ISO-Abbild](https://ubuntu.com/download/server) zu verwenden.
<!--  MACRO{toc|section=0|fromDepth=1|toDepth=6} -->

**Nachfolgende Hinweise zur Installation:**

Bei der Eingabe des root-Passworts empfehlen wir eine Kombination aus Buchstaben (Ausnahme „y“, „z“ sowie Umlaute) und Zahlen zu verwenden. Somit können sich bei einer möglicher Fehl-Konfiguration des Tastaturlayouts dennoch problemlos einloggen.

Anschließend muss ein weiterer Benutzer angelegt werden. Diesen Benutzer können Sie benennen wie Sie möchten. Name und Passwort sollten hier dennoch notiert werden. Dieser Benutzer wird nicht auf AKTIN zugreifen.

Bei der Zuteilung des Speicherplatzes bzw. der Partitionierung empfehlen wir den gesamten Speicherplatz in einer Partition zu verwenden.

![Partitionierung bei Debian][debian_disks]

Sie können die Verteilung des Speicherplatzes auch individuell gestalten. Sie sollten dabei jedoch berücksichtigen, dass die `/var`-Partition den größten Anteil des Speicherplatzes erhält. Eine separate `/home`-Partition wird nicht benötigt.

Sollte Ihr System keinen direkten Zugriff auf das Internet haben, ist es empfehlenswert, eine Proxy für die Installation einzurichten, um das Herunterladen von Sicherheitsupdates und zusätzlichen Paketen zu ermöglichen. Nach Abschluss der Installation kann der Proxyzugang wieder deaktiviert werden.

![Proxy einrichten][debian_proxy]

Im Dialogfeld für die Softwareauswahl ist darauf zu achten, dass NUR “SSH server” zusätzlich installiert wird. Alle anderen Häkchen sollten entfernt werden. Auf diese Weise wird sichergestellt, dass keine unnötige Software oder Internetdienste auf dem Server installiert werden.

![Softwareauswahl][debian_software]

Nach Abschluss des Installationsassistenten muss der Boot-Loader auf die Festplatte geschrieben werden. Dies müssen Sie explizit bestätigen.

![Boot loader][debian_bootloader]

Anschließend startet das System neu. Entfernen Sie die Installations-CD aus dem Laufwerk. Die Installation ist somit abgeschlossen und AKTIN kann im nächsten Schritt von dem [AKTIN-Installationsskript](install-script.html) installiert werden.

[debian_disks]: screens_deb/Screenshot_8.png "Gesamten Speicherplatz in einer Partition"
[debian_proxy]: screens_deb/Screenshot_14.png "Proxy für Internetzugriff einrichten"
[debian_software]: screens_deb/Screenshot_15.png "Bei Softwareauswahl nur SSH server auswählen"
[debian_bootloader]: screens_deb/Screenshot_16.png "Bootloader auf Festplatte schreiben"


Benötigte Pakete
---------------------

Sollten Sie nicht das [AKTIN-Installationsskript](install-script.html) nutzen, so werden folgende Softwarepakete benötigt:

* Java 11 Runtime Environment (openjdk-11-jre-headless)
* Postgres Datenbank Server 12 (postgresql-12)
* Apache2 (apache2)
* PHP 7.3 (php7.3 + php7.3-common + libapache2-mod-php7.3 + php7.3-curl)
* R 3.6.3 (r-base + r-cran-xml + r-cran-lattice)
* Python 3.8 (python3.8 + python3-pandas + python3-numpy + python3-requests + python3-sqlalchemy + python3-psycopg2 + python3-postgresql + python3-zipp + python3-plotly + python3-unicodecsv)

Wir empfehlen, die Software möglichst aus den gewarteten Repositories der entsprechenden Linux-Distribution zu verwenden. So können einfach und zuverlässig (Sicherheits-)Updates eingespielt werden.


Manuelle Installation anderer Distributionen
---------------------

Für manuelle Installation anderer Linux-Distributionen empfehlen wir eine Anpassung der gelieferten Skripte. Sollten Sie Fragen dazu haben, wenden Sie sich gerne an uns unter it-support(at)aktin.org
