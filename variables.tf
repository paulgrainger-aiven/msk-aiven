variable "aiven_api_token" {
  type    = string
  default = ""
}
variable "aiven_project" {
  type    = string
  default = "pgrainger-demo"
}

variable "cloud_name" {
  type    = string
  default = "google-us-west1"
}

variable "cloud_name_aws" {
  type    = string
  default = "aws-us-east-1"
}

variable "kafka_plan" {
  type    = string
  default = "business-4"
}


variable "bootstrap_servers" {
    type    = string
    default = ""
}

variable "vpc_cidr_range" {
    type    = string
    default = ""
}

variable "aws_account_id" {
    type    = string
    default = ""
}

variable "aws_vpc_id" {
    type    = string
    default = ""
}