variable "aiven_api_token" {}
variable "project_name" {}
variable "kafka_version" {}
variable "service_cloud" {}
variable "service_name_prefix" {}
variable "service_plan_kafka" {}
variable "service_plan_kafka_connect" {}
variable "service_plan_pg" {}

variable "ips" {
    type = list(object({
        network  = string,
        description = string
    }))
}

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

###################################################
# PostgreSQL
###################################################

resource "aiven_pg" "demo-postgres" {
  project                 = var.project_name
  cloud_name              = var.service_cloud
  plan                    = var.service_plan_pg
  service_name            = "${var.service_name_prefix}-postgres"

  pg_user_config {
    pg_version            = "15"

    dynamic ip_filter_object {
      for_each = var.ips
      content {
        network = ip_filter_object.value["network"]
        description =ip_filter_object.value["description"]
      }
    }
  }

}


# ###################################################
# # Apache Kafka
# ###################################################

resource "aiven_kafka" "demo-kafka" {
  project                 = var.project_name
  cloud_name              = var.service_cloud
  plan                    = var.service_plan_kafka
  service_name            = "${var.service_name_prefix}-kafka"
  default_acl             = false
  termination_protection  = false
  kafka_user_config {
    schema_registry = true
    kafka_rest = true
    kafka_version = var.kafka_version
    dynamic ip_filter_object {
      for_each = var.ips
      content {
        network = ip_filter_object.value["network"]
        description =ip_filter_object.value["description"]
      }
    }
    kafka {
      auto_create_topics_enable = true
      num_partitions = 3
      default_replication_factor = 2
    }
    kafka_authentication_methods {
      certificate = true
      sasl = true
    }
  }
}

# User reference
# =========================

data "aiven_kafka_user" "kafka_admin" {
  project = var.project_name
  service_name = aiven_kafka.demo-kafka.service_name

  # default admin user that is automatically created for each Aiven service
  username = "avnadmin"
}

# Admin ACL
resource "aiven_kafka_schema_registry_acl" "kafka-sr-acl" {
  project = var.project_name
  service_name = aiven_kafka.demo-kafka.service_name
  permission = "schema_registry_write"
  username = data.aiven_kafka_user.kafka_admin.username
  resource = "Subject:*"
}

resource "aiven_kafka_schema_configuration" "config" {
  project = var.project_name
  service_name = aiven_kafka.demo-kafka.service_name
  compatibility_level = "NONE"
}

##################################################
# Apache Kafka Connect
##################################################

resource "aiven_kafka_connect" "demo-kafka-connect" {
  project                 = var.project_name
  cloud_name              = var.service_cloud
  plan                    = var.service_plan_kafka_connect
  service_name            = "${var.service_name_prefix}-kafka-connect"

  kafka_connect_user_config {

  }

  depends_on = [
    aiven_kafka.demo-kafka
  ]
}

###################################################
# Password & schema setup
# Schema setup required for Kafka Connect
###################################################

resource "null_resource" "pg_setup" {

 provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = "${path.module}/.."
    command = "useful/resetServicePasswords.sh"
  }

 provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = "${path.module}/.."
    command = "./pgClient.sh -f setupSQL/schemaSetup.sql"
  }

 provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    working_dir = "${path.module}/.."
    command = "./pgClient.sh -f setupSQL/setupSignalTable.sql"
  }

  depends_on = [
    aiven_kafka_connect.demo-kafka-connect,aiven_pg.demo-postgres
  ]

}

###################################################
# Integrations
###################################################
###################################################

###################################################
# Kafka -> Kafka Connect (Logs)
###################################################

resource "aiven_service_integration" "demo-kafka-connect-source-integration" {
  project                  = var.project_name
  integration_type         = "kafka_connect"
  source_service_name      = aiven_kafka.demo-kafka.service_name
  destination_service_name = aiven_kafka_connect.demo-kafka-connect.service_name
}

