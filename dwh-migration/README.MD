1. Run `mvn clean install` to create a `tar.gz`-file of the migration script with `dwh-installer` (which also includes `dwh-update`). 

2. Copy the `tar.gz`-file to your server, unzip it and run `aktin_create_backup.sh` to create a zipped backup of:
    - `aktin.properties`
    - databases `aktin` and `i2b2`
    - log folders of `apache2`, `postgresql` and `wildfly`
    - the folder `/var/lib/aktin`
    <br>
3. Copy all files (including the migration script folder) temporary to an external device (like an usb-stick).

4. Update the OS of your system (preferable Ubuntu Server 20.04).

5. Copy all files back on the new OS and run `aktin_apply_backup.sh` to run `dwh-installer` and `dwh-update`, and move all backed up files back to their original destination.