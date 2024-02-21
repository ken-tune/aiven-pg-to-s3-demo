#!/bin/bash

source env.sh
source useful/get-postgres-port.sh

CONCURRENT_CONNECTIONS=10
THREADS=2
DURATION=36000
SCRIPT=testSQL/pgBenchSQL.sql
export PGPASSWORD=$AIVEN_SERVICE_PASSWORD

pgbench -h $POSTGRES_HOST -p $POSTGRES_PORT -U $AIVEN_ADMIN_USER -d defaultdb -c $CONCURRENT_CONNECTIONS -j $THREADS -T $DURATION -f $SCRIPT 2>/dev/null

