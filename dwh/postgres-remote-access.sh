#!/bin/bash


cd /etc/postgresql/9.4/main/

#
# enable client authentication (trust)
#

FILE=pg_hba.conf
if [ ! -f $FILE.orig ] ; then
	cp $FILE $FILE.orig
fi
# trust all remote connections (for development)
cat $FILE.orig > $FILE
echo 'host all all 10.0.0.2/8 trust' >> $FILE
# XXX maybe use md5 instead of trust for more security


#
# enable networking for postgresql
#

FILE=postgresql.conf
if [ ! -f $FILE.orig ] ; then
	cp $FILE $FILE.orig
fi
cat $FILE.orig | sed -e "s/^#\?listen_addresses.*\$/listen_addresses = '*'/g" > $FILE

#
# restart postgresql
#
/etc/init.d/postgresql restart
