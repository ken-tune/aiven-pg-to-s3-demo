#!/bin/bash

. env.sh
# Utility script to download certificates if not previously downloaded

if [ ! -e $CA_PATH ]
then
	echo "CA not found - downloading CA file and creating keystore"
	mkdir -p $CERTS_DIR
	avn project ca-get --target-filepath $CA_PATH --project $AIVEN_PROJECT
	keytool -keystore $TRUSTSTORE_LOCATION -alias CARoot -import -file $CA_PATH -storepass $TRUSTSTORE_PASSWORD -noprompt
fi
