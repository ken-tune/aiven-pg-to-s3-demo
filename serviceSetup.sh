#!/bin/bash

# Get login token
source aivenToken.sh

# Environment variables
source env.sh

# Build Terraform - need to to this in two stages as we do a state change
# Stage 1
cd stage-01
terraform init
terraform apply -auto-approve 
cd ..

# Stage 2
cd stage-02
terraform init
terraform apply -auto-approve
cd ..

# Clear S3 bucket
aws s3 rm s3://${AWS_S3_BUCKET_NAME} --recursive

