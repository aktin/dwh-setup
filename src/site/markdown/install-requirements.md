Voraussetzungen für eine manuelle Installation des Betriebssystems für den AKTIN-Applikations-Server
================================================================

Grundsätzlich sollte unsere Software mit allen Linux-Systemen 
verwendbar sein.

Für Debian 8 (und eingeschränkt CentOS 7) stellen wir Skripte für 
eine automatische Installation und Konfiguration zur Verfügung.

Nachfolgend ist die Installation der Pakete für ausgewählte Distributionen
beschrieben:

Debian 8
--------
Wir empfehlen für eine Neuinstallation ein Debian8-Minimalsystem ohne 
Benutzeroberfläche. Als Installationsmedium kann die [Network-Install-CD]
(https://www.debian.org/CD/netinst/) verwendet werden.

Nachfolgend Hinweise zur Installation:

Bei der Eingabe des root-Passworts empfehlen wir nur Buchstaben 
(ohne y, z und Umlaute) und Zahlen zu verwenden. Falls sich bei 
der Konfigurations des Tastaturlayouts Probleme ergeben, können
Sie sich so dennoch problemlos einloggen.

Anschließend muss ein weiterer Benutzer angelegt werden. Diesen 
Benutzer können Sie nennen wie Sie möchten - sollten aber auch hier
Name und Passwort notieren. AKTIN benötigt diesen Benutzer nicht.

Bei der Zuteilung des Speicherplatz bzw. Partitionierung empfehlen 
wir den gesamten Speicherplatz in einer Partition zu verwenden (der 
Einfachheit halber). 

![Partitionierung bei Debian][debian_disks]


Sie können die Partitionierung auch anders vornehmen, sollten dann aber
berücksichtigen, dass die `/var`-Partition den größten Anteil des
Speicherplatzes erhält. Eine separate `/home`-Partition wird nicht 
benötigt.

Wenn Ihr System keinen direkten Zugriff auf das Internet hat, sollte
für die Installation ein Proxy eingerichtet werden. Damit können 
Sicherheitsupdates und zusätzliche Pakete heruntergeladen werden.
Nach der Installation kann der Proxyzugang wieder deaktiviert werden.

![Proxy einrichten][debian_proxy]


Im Dialogfeld für die Softwareauswahl ist darauf zu achten, dass 
ein Haken NUR bei "SSH server" gesetzt ist. Alle anderen Haken 
sollten entfernt werden. Auf diese Weise wird sichergestellt, dass 
keine unnötige Software oder Internetdienste auf dem Server 
installiert werden. 

![Softwareauswahl][debian_software]

Nach Abschluss des Installationsassistenten muss der Boot-Loader
auf die Festplatte geschrieben werden. Dies müssen Sie explizit
bestätigen.

![Boot loader][debian_bootloader]

Anschließend started der Server neu (vorher CD entfernen).

Nach der Installation kann unser [AKTIN-Installationsskript](install-script.html) 
alle weiteren Schritte automatisch durchführen.


[debian_disks]: screens_deb/Screenshot_8.png "Gesamten Speicherplatz in einer Partition"
[debian_proxy]: screens_deb/Screenshot_14.png "Proxy für Internetzugriff einrichten"
[debian_software]: screens_deb/Screenshot_15.png "Bei Softwareauswahl nur SSH server auswählen"
[debian_bootloader]: screens_deb/Screenshot_16.png "Bootloader auf Festplatte schreiben"

CentOS 7
--------

Auch bei CentOS 7 genügt eine Minimalinstallation ohne Benutzeroberfläche oder
weitere Internetdienste. Bitte beachten Sie bei der Installation die Hinweise 
wie bei Debian 8 angegeben.

Nach der Installation kann unser [AKTIN-Installationsskript](install-script.html) 
alle weiteren Schritte automatisch durchführen.



Andere Distributionen
---------------------

Die folgende Software wird benötigt:

* Apache2 + PHP5 + php_curl + mod_proxy (http)
* Postgres Datenbank Server
* Java 8 runtime environment (headless ausreichend)

Wir empfehlen die Software möglichst aus den gewarteten Repositories
der entsprechenden Linux-Distribution zu verwenden. So können einfach 
und zuverlässig (Sicherheits-)Updates eingespielt werden.


Nachfolgend Paketnamen der gängigen Distributionen

| Paket | Debian 8 | CentOS 7 |
|---|---|---|
| Postgres | postgresql | postgresql-server, postgresql-contrib |
| Java 8 JRE | openjdk-8-jre-headless* | java-1.8.0-openjdk-headless |
| PHP5 curl | php5-curl | php-curl |
| R | r-cran-xml r-cran-lattice | R |


Manuelle Installation
---------------------

Für manuelle Installation anderer Linux-Distributionen empfehlen wir eine Anpassung der gelieferten Skripte. Sollten Sie Fragen dazu haben, wenden Sie sich gerne an uns unter it-support(at)aktin.de
