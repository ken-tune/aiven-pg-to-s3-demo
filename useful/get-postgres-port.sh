#!/bin/bash

. env.sh

# Utility script to get the Cassandra service port
export POSTGRES_PORT=$(avn service get ${SERVICE_NAME_PREFIX}-postgres --project $AIVEN_PROJECT --json | jq '.service_uri_params.port' | sed 's/"//g')
