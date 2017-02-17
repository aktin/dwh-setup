Generic Update Procedure
------------------------
not supported:
pre-0.6

currently supported:
0.6
0.6.3


notation [all]=executed for all updates; [pre yy]=executed only if the version before upgrade is yy or lower
-------------------

Step 0) Check Paths and Log Status Information (target and active EAR version etc.) [all]

Step 1) Undeploy all old dwh-j2ee EARs [all]

Step 2) Execute scripts (SQL, Copy files etc.) [all]

Step 2.01) Fact Database Reset [pre 0.6.3]

Step 2.02) Update local DWH ontology [all]

Step 2.03) Remove login form defaults [pre 0.6.3]

Step 2.04) Create AKTIN Database in postgres [pre 0.7]

Step 2.05) Create Aktin Data source in wildfly [pre 0.7]

Step 2.06) Copy aktin.properties [pre 0.7]

Step 2.07) Create /var/lib/aktin [pre 0.7]

Step 2.08) SMTP configuration [pre 0.7]

Step 3) Stop Wildfly Service [all]

Step 4) Remove all dwh.ear, dwh.ear.failed, dwh.ear.undeployed

Step 5) Start Wildfly Service [all]

Step 6) Copy/Deploy new dwh-j2ee EAR [all]

