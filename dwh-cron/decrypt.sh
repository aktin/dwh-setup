#!/usr/bin/env bash

SCRIPT=$(readlink -f "$0")
FILE_ROOT=$(dirname "$SCRIPT")

TAR_FILE=foo.tgz
TEMP_DIR=out
DEST_DIR=$FILE_ROOT

MAIN_FILE=secret.txt
KEY_FILE=secret.txt.key

# usage:
# ./decrypt.sh foo.tgz out .

if [ $# -gt 1 ]; then 
	TAR_FILE=$1
	shift
fi
if [ $# -gt 1 ]; then 
	TEMP_DIR=$1
	shift
fi
if [ $# -gt 1 ]; then 
	DEST_DIR=$1
	shift
fi

mkdir $TEMP_DIR
tar zxvf $TAR_FILE -C $TEMP_DIR
openssl rsautl -decrypt -ssl -inkey .ssh/id_rsa -in $TEMP_DIR/$KEY_FILE.enc -out $TEMP_DIR/$KEY_FILE
openssl aes-256-cbc -d -in $TEMP_DIR/$MAIN_FILE.enc -out $DEST_DIR/$MAIN_FILE -pass file:$TEMP_DIR/$KEY_FILE
rm -r $TEMP_DIR