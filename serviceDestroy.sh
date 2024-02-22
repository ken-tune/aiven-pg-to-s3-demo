#!/bin/bash

# Get login token
source aivenToken.sh

# Environment variables
source env.sh

# Build Terraform - need to to this in two stages as we do a state change
# Stage 2
cd stage-02
terraform init
terraform destroy -auto-approve 
cd ..

# Stage 1
cd stage-01
terraform init
terraform destroy -auto-approve
cd ..
