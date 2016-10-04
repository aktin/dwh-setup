Installation des AKTIN DWH Servers
==================================

Diese Informationen richten sich an die Server-Administratoren, die für die Einrichtung bzw. Wartung der Linux-Server in den Kliniken zuständig sind, auf denen das AKTIN-Datawarehouse läuft.

Beschrieben wird das Vorgehen für eine Neuinstallation, verschiedene Varianten zum Update sowie optionale Konfigurationsschritte.

Neuinstallation
---------------
Wenn Sie noch keine Installation haben, oder den Server komplett neu aufsetzen wollen, dann folgen Sie bitte der Anleitung unter dem Punkt AKTIN (NEU-)INSTALLATION. Bitte beachten Sie die [Voraussetzungen](install-requirements.html), dort werden die verschiedenen Varianten der Neu-Installation beschrieben.

Aktuell erreichen Sie mit einer Neuinstallation in jedem Fall den Release-Stand 0.5, d.h. anschließend muss noch das automatische oder manuelle Update durchgeführt werden.


Skriptbasiertes Update für Debian
---------------------------------
Falls Sie einen Debian-Server nutzen, der anhand der Anleitung eingerichtet wurde, sollten die Update-Scripte bei Ihnen funktionieren.

__Update 0.5->0.6.2__

Falls Sie noch kein Update durchgeführt haben (d.h. Sie haben eine Installation mit dem Release-Stand 0.5) folgen Sie der Anleitung zum [automatischen Update](auto-update-0.6.html)

__Patch Update 0.6->0.6.2__

Falls sie bereits auf dem Release 0.6 sind, folgen Sie zum Patchen auf 0.6.2 bitte folgender [Anleitung](patch-0.6.x.html)


Manuelles Update für Debian, CentOS oder andere Betriebssysteme
----------------------------------------------------------------
Bei individuell konfigurierten Servern oder anderen Linux-Distributionen führen Sie die einzelnen Schritte des Scripts bitte manuell durch und passen Sie ggf. die Pfade oder andere Besonderheiten entsprechend an.

__Update 0.5->0.6.2__

Bitte folgen Sie der Anleitung zum [manuellen Update](manual-update-0.6.html)

__Patch Update 0.6->0.6.2__

Falls sie bereits auf dem Release 0.6 sind, folgen Sie zum Patchen auf 0.6.2 bitte folgender [Anleitung](patch-0.6.x.html)


Optionale Schritte bei der Installation
---------------------------------------
Die [optionalen Schritte](optional.html) können nach der automatischen Installation sowie der manuellen Installation durchgeführt werden. Die Einrichtung es E-Mail-Dienstes wird erst in einer späteren Version nötig.