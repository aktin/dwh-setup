Creating a prepared DVD for Semi-automatic installation
=======================================================
Generate ISO
------------
Call `mvn clean install` to create the installer package of `dwh-install`.
In `aktin-cdd`, call `mvn clean install` to generate the folder `target/debian-cdd-0.1-SNAPSHOT`. Either call `vagrant up` in this folder to create the vagrant machine and build an ISO, or move or copy the whole folder some where else to do so, e.g. on the server.
The generated ISO will be in put in the folder itself. 

To create the ISO again, call `vagrant ssh` and then: 
```
vagrant@debian-8:~$ ls
aktin-cdd
vagrant@debian-8:~$ cd aktin-cdd/
vagrant@debian-8:~/aktin-cdd$ ls
images  local_extras  profiles  tmp
vagrant@debian-8:~/aktin-cdd$ build-simple-cdd --profiles aktin
```
The new image is located in the `images` folder as listed above. Call `cp images/debian-8.3-amd64-CD-1.iso /vagrant/` to copy the new image to the root folder of vagrant. Important: If there is already an older image, the older ISO will be overwritten.

Profiles
--------
The main changes to the default installation of `simple-cdd` is made in `/usr/share/simple-cdd/tools/build/debian-cd` in lines 96-99, to include the folder `cd_extras="$simple_cdd_dir/local_extras"` as defined in `profiles/aktin.conf`. Now, all ressources in the defined folder will be included on the ISO.
To deactivate the full automation of the installer and prompt the network configurations, the file `/usr/share/simple-cdd/profiles/default.preseed` is overwritten, to disable the following options in the lines 80, 85 and 86
```
# d-i netcfg/choose_interface select auto
[...]
# d-i netcfg/get_hostname string unassigned
# d-i netcfg/get_domain string unassigned
```
In the config file `profiles/aktin.conf` the base parameters and mirror settings are defined. For `openjdk-8-jre-headless` the backports have to be activated. 
All packages listed in `profile/aktin.packages` will be installed with dependencies. `openjdk-8-jre-headless` must also be listed to be installed.
In `profiles/aktin.preseed` the settings for the installer are more specified. In line 29, the base system will be configured as an SSH server. For every config not listed here, the default config in `profile/default.preseed` or `/usr/share/simple-cdd/profiles/default.preseed` will be used.
The script `profiles/aktin.postinst` will be called once the installation of the base system is finished. This script will be run with root rights. In this case, the ISO is mounted again and the `aktin-installer.tar.gz` copied to the local system and the aktin installer is called. 
