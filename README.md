# Introduction

This example details how to push data from MSK on a private VPC in AWS, to Aiven for Kafka via MirrorMaker. 

The services are provisioned with Terraform. However to fully complete the example, the VPC peering connections need manual intervention in both the AWS and GCP consoles. 

# Prerequisites 

## Accounts

You will need an account with Aiven, AWS and Google to run through this example

Aiven https://console.aiven.io/signup/email

AWS https://aws.amazon.com/resources/create-account/

Google https://console.cloud.google.com/freetrial/signup/tos

## Tools

### Terraform

Terraform will be used to provision services in your Aiven account. Navigate to https://www.terraform.io/downloads and follow the steps to set up on your local machine

### Aiven Command Line Tool

The Aiven command line tool will be used to generate permission tokens which enable us to provision services with Terraform in our Aiven account. 

Install using pip then log into your account
```
pip install aiven-client
```

```
avn user login me@email.com --token
```

### jq
jq is a lightweight and flexible command-line JSON processor. We use this below to retrieve the authentication token from a JSON object. 

https://github.com/stedolan/jq/wiki/Installation

# Setting up services

## Authentication Token

Terraform requires an authentication token to provision the services. I recommend creating a temporary token for this task which expires after a set amount of seconds (6000 below)

```
TOKEN=$(avn user access-token create --description "temporary token" --max-age-seconds 6000 --json|jq ".[0].full_token"|sed 's/"//g')
```

## Kafka Settings

In your MSK cluster settings, find the connection strings to the brokers and update `BOOTSTRAP_SERVERS` below with the string. 

Note this assumes you are using PLAINTEXT. If you wish to use SASL/SASL SSL you will need to update the example here to add additional information. 

```
# MSK settings
BOOTSTRAP_SERVERS=broker1:9092,broker2:9092,broker3:9092
```

## VPC Settings

For both your AWS and GCP VPCs, fill in the below variables with the correct values.

```
# AWS VPC network settings
AWS_CIDR_RANGE=10.0.0.0/24
AWS_ACCOUNT_ID=222211110000
AWS_VPC_ID=my-aws-vpc-id

# GPC VPC network settings
GCP_CIDR_RANGE=10.1.0.0/24
GCP_ACCOUNT_ID=222211110000
GCP_VPC_ID=my-gcp-vpc-id
```

## Executing 
Once the above are set, you can execute the following commands to provision services in your Aiven project

```
terraform init

terraform plan

terraform apply 
  -var="aiven_api_token=$TOKEN" \
  -var="bootstrap_servers=$BOOTSTRAP_SERVERS" \
  -var="aws_account_id=$AWS_ACCOUNT_ID" \
  -var="aws_vpc_id=$AWS_VPC_ID" \
  -var="aws_vpc_cidr_range=$AWS_CIDR_RANGE" \
  -var="gcp_account_id=$GCP_ACCOUNT_ID" \
  -var="gcp_vpc_id=$GCP_VPC_ID" \
  -var="gcp_vpc_cidr_range=$GCP_CIDR_RANGE"

```
