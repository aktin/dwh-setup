#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
cur_root=$(dirname "$SCRIPT")
outdir=$cur_root/output

localname="wolfsburg"
weeknr=$(($(date +"%V")-1))
sqlname=$cur_root/nlga_abfrage_weekly.sql
outname=$outdir/nlga_$localname"_"$weeknr.csv

if [ ! -d "$outdir" ]; then 
    mkdir $outdir
    chmod -R 777 $outdir
fi

su - postgres bash -c "psql -d i2b2 -t -A -F"," -f $sqlname -o $outname"
