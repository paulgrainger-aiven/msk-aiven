resource "aiven_project_vpc" "vpc_aws" {
  project      = var.aiven_project
  cloud_name   = var.cloud_name_aws
  network_cidr = var.vpc_cidr_range

  timeouts {
    create = "5m"
  }
}

resource "aiven_aws_vpc_peering_connection" "aws_peer" {
  vpc_id         = aiven_project_vpc.vpc_aws.id
  aws_account_id = var.aws_account_id
  aws_vpc_id     = var.aws_vpc_id
  aws_vpc_region = "us-east-1"
}

resource "aiven_kafka" "kafka" {
    project        = var.aiven_project
    cloud_name     = var.cloud_name
    plan           = var.kafka_plan
    service_name   = "my-kafka-demo"

    kafka_user_config {
        kafka_rest      = true
        schema_registry = true
        kafka_version   = "3.1"
    }
}

# resource "aiven_kafka" "kafka_prev_version" {
#     project        = var.aiven_project
#     cloud_name     = var.cloud_name
#     plan           = var.kafka_plan
#     service_name   = "kafka-upgrade-test"

#     kafka_user_config {
#         kafka_rest      = true
#         schema_registry = true
#         kafka_version   = "3.0"
#     }
# }


resource "aiven_kafka_mirrormaker" "mm" {
  project        = var.aiven_project
  project_vpc_id = aiven_project_vpc.vpc_aws.id
  cloud_name     = var.cloud_name_aws  
  plan           = "startup-4"
  service_name   = "mm"

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
    endpoint_name = "MSK-demo"
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
