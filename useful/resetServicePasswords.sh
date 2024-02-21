#!/bin/bash

source env.sh

for service_type in postgres kafka-connect kafka
do
	SERVICE_NAME=${SERVICE_NAME_PREFIX}-$service_type
	avn service user-password-reset $SERVICE_NAME --project $AIVEN_PROJECT --username $AIVEN_ADMIN_USER --new-password $AIVEN_SERVICE_PASSWORD
done
