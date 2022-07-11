variable "aiven_api_token" {
  type    = string
  default = ""
}
variable "aiven_project" {
  type    = string
  default = "pgrainger-demo"
}

variable "cloud_name_gcp" {
  type    = string
  default = "google-us-west1"
}

variable "cloud_name_aws" {
  type    = string
  default = "aws-us-east-1"
}

variable "vpc_region_aws" {
  type    = string
  default = "us-east-1"
}

variable "bootstrap_servers" {
    type    = string
    default = ""
}

variable "aws_vpc_cidr_range" {}
variable "aws_account_id" {}
variable "aws_vpc_id" {}

variable "gcp_vpc_cidr_range" {}
variable "gcp_account_id" {}
variable "gcp_vpc_id" {}
