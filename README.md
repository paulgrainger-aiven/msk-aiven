# Running terraform


Gather the following settings and update the below to meet your needs

```
TOKEN=$(avn user access-token create --description "temporary token" --max-age-seconds 600 --json|jq ".[0].full_token"|sed 's/"//g')

# MSK settings
BOOTSTRAP_SERVERS=broker1:9092,broker2:9092,broker3:9092

# AWS VPC network settings
AWS_CIDR_RANGE=10.0.0.0/24
AWS_ACCOUNT_ID=222211110000
AWS_VPC_ID=my-aws-vpc-id

# GPC VPC network settings
GCP_CIDR_RANGE=10.1.0.0/24
GCP_ACCOUNT_ID=222211110000
GCP_VPC_ID=my-gcp-vpc-id
```

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
  -var="gcp_vpc_cidr_range=$GCP_CIDR_RANGE" \  

```