variable "aiven_api_token" {}
variable "project_name" {}
variable "service_name_prefix" {}
variable "aws_access_key_id" {}
variable "aws_secret_access_key" {}
variable "aws_s3_bucket_name" {}
variable "aws_s3_region" {}

terraform {
  required_providers {
    aiven = {
      source = "aiven/aiven"
      version = ">= 4.0.0, < 5.0.0"
    }
  }
}

provider "aiven" {
  api_token = var.aiven_api_token
}

locals {
  schema_registry_uri = "https://${data.aiven_service_component.schema_registry.host}:${data.aiven_service_component.schema_registry.port}"
  schema_registry_creds = "${data.aiven_kafka_user.kafka_admin.username}:${data.aiven_kafka_user.kafka_admin.password}"
}

# Existing resources
# =========================

data "aiven_pg" "demo-postgres" {
  project                 = var.project_name
  service_name            = "${var.service_name_prefix}-postgres"
}

data "aiven_kafka" "demo-kafka" {
  project                 = var.project_name
  service_name            = "${var.service_name_prefix}-kafka"
}

data "aiven_kafka_connect" "demo-kafka-connect" {
  project                 = var.project_name
  service_name            = "${var.service_name_prefix}-kafka-connect"  
}

# Schema Registry reference
# =========================

data "aiven_service_component" "schema_registry" {
  project = var.project_name
  service_name = data.aiven_kafka.demo-kafka.service_name
  component = "schema_registry"
  route = "dynamic"
}

# User reference
# =========================

data "aiven_kafka_user" "kafka_admin" {
  project = var.project_name
  service_name = data.aiven_kafka.demo-kafka.service_name

  # default admin user that is automatically created for each Aiven service
  username = "avnadmin"
}

###################################################
# Kafka Connect -> S3 (Logs)
###################################################

resource "aiven_kafka_connector" "kafka-s3-sink" {
  project        = var.project_name
  service_name   = data.aiven_kafka_connect.demo-kafka-connect.service_name
  connector_name = "${var.service_name_prefix}-kafka-s3-sink"
  config = {
    "name"                  = "${var.service_name_prefix}-kafka-s3-sink"
    "connector.class" = "io.aiven.kafka.connect.s3.AivenKafkaConnectS3SinkConnector"
    "aws.access.key.id"     = var.aws_access_key_id
    "aws.secret.access.key" = var.aws_secret_access_key
    "aws.s3.bucket.name"    = var.aws_s3_bucket_name
    "aws.s3.region"         = var.aws_s3_region
    "topics" = "replicator.demo.products"
    "format.output.fields" = "value"
    "format.output.envelope" = false
    "format.output.type"    = "parquet"
    "key.converter"           = "io.confluent.connect.avro.AvroConverter"
    "key.converter.schema.registry.url" = "${local.schema_registry_uri}"
    "key.converter.basic.auth.credentials.source" =  "USER_INFO"
    "key.converter.schema.registry.basic.auth.user.info" = "${local.schema_registry_creds}"
    "key.converter.schemas.enable" = "true"
    "value.converter"           = "io.confluent.connect.avro.AvroConverter"
    "value.converter.schema.registry.url" = "${local.schema_registry_uri}"
    "value.converter.basic.auth.credentials.source" =  "USER_INFO"
    "value.converter.schema.registry.basic.auth.user.info" = "${local.schema_registry_creds}"
    "value.converter.schemas.enable" = "true"

  }
}

###################################################
# Postgres -> Kafka Connect (Logs)
###################################################

resource "aiven_kafka_connector" "kafka-pg-source" {
  project        = var.project_name
  service_name   = data.aiven_kafka_connect.demo-kafka-connect.service_name
  connector_name = "${var.service_name_prefix}-kafka-source-connector"

  config = {
    "_aiven.restart.on.failure" = true
    "name"                      = "${var.service_name_prefix}-kafka-source-connector"
    "connector.class"           = "io.debezium.connector.postgresql.PostgresConnector"
    "snapshot.mode"             = "initial"
    "database.hostname"         = data.aiven_pg.demo-postgres.service_host
    "database.port"             = data.aiven_pg.demo-postgres.service_port
    "database.password"         = data.aiven_pg.demo-postgres.service_password
    "database.user"             = data.aiven_pg.demo-postgres.service_username
    "database.dbname"           = "defaultdb"
    "database.server.name"      = "replicator"
    "slot.name"                 = "products_repl_slot",
    "publication.name"          = "products_publication",
    "database.ssl.mode"         = "require"
    "include.schema.changes"    = true
    "include.query"             = true
    "table.include.list"        = "demo.products,demo.debezium_signals,demo.heartbeat" 
    "plugin.name"               = "pgoutput"
    "decimal.handling.mode"     = "double"
    "_aiven.restart.on.failure" = "true"
    "heartbeat.interval.ms"     = 30000
    "heartbeat.action.query"    = "INSERT INTO demo.heartbeat (status) VALUES ('OK')"
    "key.converter"           = "io.confluent.connect.avro.AvroConverter"
    "key.converter.schema.registry.url" = "${local.schema_registry_uri}" 
    "key.converter.basic.auth.credentials.source" =  "USER_INFO"
    "key.converter.schema.registry.basic.auth.user.info" = "${local.schema_registry_creds}"
    "key.converter.schemas.enable" = "true"
    "value.converter"           = "io.confluent.connect.avro.AvroConverter"
    "value.converter.schema.registry.url" = "${local.schema_registry_uri}" 
    "value.converter.basic.auth.credentials.source" =  "USER_INFO"
    "value.converter.schema.registry.basic.auth.user.info" = "${local.schema_registry_creds}"
    "value.converter.schemas.enable" = "true"
    "signal.data.collection" = "demo.debezium_signals"    
    "transforms"="unwrap"
    "transforms.unwrap.type"="io.debezium.transforms.ExtractNewRecordState"
    "transforms.unwrap.drop.tombstones"="true"
    "transforms.unwrap.delete.handling.mode"="rewrite"
  }
}
