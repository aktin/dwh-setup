#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
FILE_ROOT=$(dirname "$SCRIPT")

TAR_FILE=foo.tgz
TEMP_DIR=enc

MAIN_PATH=./secret.txt
KEY_FILE=secret.txt.key

# usage:
# ./encrypt.sh secret.txt foo.tgz 

if [ $# -gt 1 ]; then 
	MAIN_PATH=$1
	shift
fi
if [ $# -gt 1 ]; then 
	TAR_FILE=$1
	shift
fi

MAIN_FILE=$(basename $MAIN_PATH)

# make random key
openssl rand 192 -out $TEMP_DIR/$KEY_FILE

openssl aes-256-cbc -in $MAIN_PATH -out $TEMP_DIR/$MAIN_FILE.enc -pass file:$TEMP_DIR/$KEY_FILE
openssl rsautl -encrypt -pubin -inkey $FILE_ROOT/.ssh/id_rsa.pub.pkcs8 -in $TEMP_DIR/$KEY_FILE -out $TEMP_DIR/$KEY_FILE.enc
tar zcvf foo.tgz $TEMP_DIR/*.enc



# http://php.net/manual/de/function.openssl-encrypt.php
