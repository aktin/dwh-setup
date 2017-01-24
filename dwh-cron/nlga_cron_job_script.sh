#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
cur_root=$(dirname "$SCRIPT")
outdir=$cur_root/output

localname="wolfsburg"
weeknr=$(($(date +"%V")-1))
sqlname=$cur_root/nlga_abfrage_weekly.sql
outname=nlga_$localname"_"$weeknr.csv

if [ ! -d "$outdir" ]; then 
    mkdir $outdir
    chmod -R 777 $outdir
fi

su - postgres bash -c "psql -d i2b2 -t -A -F"," -f $sqlname -o $outdir/$outname"

# encryption

# BASE_PASS="NLGA_AKTIN_REND"

# zip -P "${BASE_PASS}_${localname}_${weeknr}" $outdir/$outname.zip $outdir/$outname


TEMP_DIR=$cur_root/tmp_enc
KEY_FILE=secret.key
KEY_EXT=enckey
FILE_EXT=encfile
PUB_KEY=aktin_rsa.pub.pkcs8

mkdir $TEMP_DIR

# make random key
openssl rand 192 -out $TEMP_DIR/$KEY_FILE

openssl aes-256-cbc -in $outdir/$outname -out $TEMP_DIR/$outname.$FILE_EXT -pass file:$TEMP_DIR/$KEY_FILE
openssl rsautl -encrypt -pubin -inkey $cur_root/$PUB_KEY -in $TEMP_DIR/$KEY_FILE -out $TEMP_DIR/$KEY_FILE.$KEY_EXT
tar zcvf $outdir/$outname.tgz $TEMP_DIR/$KEY_FILE.$KEY_EXT $TEMP_DIR/$outname.$FILE_EXT

rm -r $TEMP_DIR
