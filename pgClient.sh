#!/bin/bash

source env.sh
source useful/get-postgres-port.sh

psql "postgres://$AIVEN_ADMIN_USER:${AIVEN_SERVICE_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/defaultdb?sslmode=require" $@
