#!/bin/bash

source userSpecific.sh

# Default service user name
AIVEN_ADMIN_USER=avnadmin

# Service name prefix
SERVICE_NAME_PREFIX=aiven-demo

# Root directory for any install assets

# Host name
POSTGRES_HOST=${SERVICE_NAME_PREFIX}-postgres-${AIVEN_PROJECT}.a.aivencloud.com

# CA certificate details
CERTS_DIR=certs

# Needed in a truststore for cassandra-stress
TRUSTSTORE_LOCATION=$CERTS_DIR/myTrustStore.jks
TRUSTSTORE_PASSWORD=my_truststore_password

# And exported as SSL_CERTFILE for cqlsh
CA_PATH=$CERTS_DIR/ca.pem
export SSL_CERTFILE=$CA_PATH

# Add useful things to paths
PATH=$PATH:$CASSANDRA_TOOLS_DIR/tools/bin:$CASSANDRA_TOOLS_DIR/bin

# Need to export some variables to Terraform so they can be used
export TF_VAR_project_name=$AIVEN_PROJECT
export TF_VAR_service_name_prefix=$SERVICE_NAME_PREFIX
export TF_VAR_aws_access_key_id=$AWS_ACCESS_KEY_ID
export TF_VAR_aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
export TF_VAR_aws_s3_bucket_name=$AWS_S3_BUCKET_NAME
export TF_VAR_aws_s3_region=$AWS_S3_REGION

export AIVEN_PROJECT
