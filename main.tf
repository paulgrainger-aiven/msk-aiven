variable "kafka_name" {}
variable "kafka_plan" {}
variable "mm_name" {}
variable "mm_plan" {}
variable "m3_name" {}
variable "m3_plan" {}
variable "grafana_name" {}
variable "grafana_plan" {}

resource "aiven_project_vpc" "vpc_aws" {
  project      = var.aiven_project
  cloud_name   = var.cloud_name_aws
  network_cidr = var.aws_vpc_cidr_range

  timeouts {
    create = "5m"
  }
}

resource "aiven_project_vpc" "vpc_gcp" {
  project      = var.aiven_project
  cloud_name   = var.cloud_name_gcp
  network_cidr = var.gcp_vpc_cidr_range

  timeouts {
    create = "5m"
  }
}

resource "aiven_aws_vpc_peering_connection" "aws_peer" {
  vpc_id         = aiven_project_vpc.vpc_aws.id
  aws_account_id = var.aws_account_id
  aws_vpc_id     = var.aws_vpc_id
  aws_vpc_region = var.vpc_region_aws
}

resource "aiven_gcp_vpc_peering_connection" "gcp_peer" {
  vpc_id         = aiven_project_vpc.vpc_gcp.id
  gcp_project_id = var.gcp_account_id
  peer_vpc       = var.gcp_vpc_id
}


resource "aiven_kafka" "kafka" {
    project        = var.aiven_project
    cloud_name     = var.cloud_name_gcp
    project_vpc_id = aiven_project_vpc.vpc_gcp.id
    plan           = var.kafka_plan
    service_name   = var.kafka_name

    kafka_user_config {
        kafka_rest      = true
        schema_registry = true
        kafka_version   = "3.1"
    }
}


resource "aiven_kafka_mirrormaker" "mm" {
  project        = var.aiven_project
  project_vpc_id = aiven_project_vpc.vpc_aws.id
  cloud_name     = var.cloud_name_aws  
  plan           = var.mm_plan
  service_name   = var.mm_name

  kafka_mirrormaker_user_config {
    ip_filter = [
      "0.0.0.0/0"
    ]

    kafka_mirrormaker {
      refresh_groups_interval_seconds = 600
      refresh_topics_enabled          = true
      refresh_topics_interval_seconds = 600
    }
  }
}

resource "aiven_service_integration_endpoint" "ext_kafka" {
    project       = var.aiven_project
    endpoint_name = "MSK-demo-1"
    endpoint_type = "external_kafka"
    external_kafka_user_config {
				bootstrap_servers = var.bootstrap_servers
				security_protocol="PLAINTEXT"
			}
}

resource "aiven_service_integration" "ext_kafka_mm" {
    project                  = var.aiven_project
    source_endpoint_id       = aiven_service_integration_endpoint.ext_kafka.id
    destination_service_name = aiven_kafka_mirrormaker.mm.service_name
    integration_type         = "kafka_mirrormaker"

    kafka_mirrormaker_user_config {
        cluster_alias="MSK"
    }

    depends_on=[aiven_service_integration_endpoint.ext_kafka]
}

resource "aiven_service_integration" "target-mm" {
  project                  = var.aiven_project
  source_service_name      = aiven_kafka.kafka.service_name
  destination_service_name = aiven_kafka_mirrormaker.mm.service_name
  integration_type         = "kafka_mirrormaker"

  kafka_mirrormaker_user_config {
    cluster_alias="target"
  }

}

resource "aiven_mirrormaker_replication_flow" "msk-aiven" {
  project        = var.aiven_project
  service_name   = aiven_kafka_mirrormaker.mm.service_name
  target_cluster = "target"
  source_cluster = "MSK"
  enable = true
  topics = [
    "\\.*",
  ]
  topics_blacklist = [
    ".*[\\-\\.]internal",
    ".*\\.replica",
    "__.*"
  ]
  depends_on = [aiven_kafka_mirrormaker.mm]
}

resource "aiven_m3db" "m3db-metrics" {
  project        = var.aiven_project
  cloud_name     = var.cloud_name_gcp
  project_vpc_id = aiven_project_vpc.vpc_gcp.id
  plan           = "startup-8"
  service_name   = "m3db-metrics"

  m3db_user_config {
    m3db_version = 1.5
    namespaces {
      name = "default_ns"
      type = "unaggregated"
      options {
        retention_options {
          retention_period_duration = "2h"
        }
      }
    }
  }
}

resource "aiven_grafana" "grafana" {
  project        = var.aiven_project
  cloud_name     = var.cloud_name_gcp
  project_vpc_id = aiven_project_vpc.vpc_gcp.id
  plan           = "startup-1"
  service_name   = "grafana"

  grafana_user_config {
    public_access {
      grafana = true
    }
  }
}

resource "aiven_service_integration" "kafka_metrics" {
  project                  = var.aiven_project
  integration_type         = "metrics"
  source_service_name      = aiven_kafka.kafka.service_name
  destination_service_name = aiven_m3db.m3db-metrics.service_name
}

resource "aiven_service_integration" "grafana_dashboard" {
  project                  = var.aiven_project
  integration_type         = "dashboard"
  source_service_name      = aiven_grafana.grafana.service_name
  destination_service_name = aiven_m3db.m3db-metrics.service_name
}
