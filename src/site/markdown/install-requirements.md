Manuelle Installation des Betriebssystems für den AKTIN-Applikationsserver
===============================================
Grundsätzlich ist die Software auf allen Linux-Systemen verwendbar. Für eine manuelle Installation anderer Linux-Distributionen empfehlen wir eine Anpassung der gelieferten Skripte. Sollten Sie Fragen dazu haben, wenden Sie sich gerne an uns unter [it-support@aktin.org](mailto:it-support@aktin.org).

Für Ubuntu 20.04 LTS werden Skripte für eine automatische Installation und Konfiguration bereitgestellt. Es wird an dieser Stelle explizit darauf verwiesen, dass das Installationsskript aktuell nur mit Ubuntu 20.04 LTS und Ubuntu 18.04 LTS getestet wurde. Für eine Neuinstallation wird [Ubuntu Server 20.04 LTS](https://ubuntu.com/download/server) empfohlen. Dabei handelt es sich um eine minimalistische Ubuntu-Version optimiert für das Betreiben von Servern.

<!--  MACRO{toc|section=0|fromDepth=1|toDepth=6} -->


Nachfolgende Hinweise zur Installation
---------------------
- **Configure proxy**<br>
Sollte Ihr System keinen direkten Zugriff auf das Internet haben, ist es empfehlenswert, eine Proxy für die Installation einzurichten, um das Herunterladen von Sicherheitsupdates und zusätzlichen Paketen zu ermöglichen. Nach Abschluss der Installation kann der Proxyzugang wieder deaktiviert werden.

![installation_ubuntu_proxy](screens_ubuntu/ubuntu_5.png)

- **Profile setup**<br>
Bei der Eingabe des root-Passworts empfehlen wir eine Kombination aus Buchstaben (Ausnahme „y“, „z“ sowie Umlaute) und Zahlen zu verwenden. Somit können sich bei einer möglicher Fehl-Konfiguration des Tastaturlayouts dennoch problemlos einloggen. Anschließend muss ein weiterer Benutzer angelegt werden. Diesen Benutzer können Sie benennen wie Sie möchten. Name und Passwort sollten hier dennoch notiert werden. Dieser Benutzer wird nicht auf AKTIN zugreifen.

![installation_ubuntu_profile](screens_ubuntu/ubuntu_10.png)

- **Storage configuration**<br>
Bei der Zuteilung des Speicherplatzes bzw. der Partitionierung empfehlen wir den gesamten Speicherplatz in einer Partition zu verwenden. Sie können die Verteilung des Speicherplatzes auch individuell gestalten. Sie sollten dabei jedoch berücksichtigen, dass die `/var`-Partition den größten Anteil des Speicherplatzes erhält. Eine separate `/home`-Partition wird nicht benötigt.

![installation_ubuntu_storage](screens_ubuntu/ubuntu_8.png)

- **SSH Setup + Featured Server Snaps**<br>
Im Dialogfeld für die Softwareauswahl ist darauf zu achten, dass NUR “SSH server” zusätzlich installiert wird. Alle anderen Häkchen sollten entfernt werden. Auf diese Weise wird sichergestellt, dass keine unnötige Software oder Internetdienste auf dem Server installiert werden.

![installation_ubuntu_ssh](screens_ubuntu/ubuntu_11.png)

![installation_ubuntu_snaps](screens_ubuntu/ubuntu_12.png)

- **Bootloader**<br>
Nach Abschluss des Installationsassistenten muss der Boot-Loader auf die Festplatte geschrieben werden. Dies müssen Sie explizit bestätigen. Anschließend startet das System neu. Die Installation ist somit abgeschlossen und AKTIN kann im nächsten Schritt von dem [AKTIN-Installationsskript](install-script.html) installiert werden.
