#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
cur_root=$(dirname "$SCRIPT")

cronrootfile=/var/spool/cron/crontabs/root
if [ ! -f "$cronrootfile" ]; then 
	echo no tap
    #crontab /etc/crontab 
    echo "SHELL=/bin/sh\n"  >> $cronrootfile
    echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin\n"  >> $cronrootfile
    echo "# m h  dom mon dow   command\n"  >> $cronrootfile

fi

echo "33 5    * * 1   $cur_root/nlga_cron_job_script.sh" >> $cronrootfile

