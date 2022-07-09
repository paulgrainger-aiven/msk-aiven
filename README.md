# Running terraform


Gather the following settings and update the below to meet your needs

```
TOKEN=$(avn user access-token create --description "temporary token" --max-age-seconds 600 --json|jq ".[0].full_token"|sed 's/"//g')
BOOTSTRAP_SERVERS=broker1:9092,broker2:9092,broker3:9092
CIDR_RANGE=10.0.0.0/24
AWS_ACCOUNT_ID=222211110000
AWS_VPC_ID=my-aws-vpc-id
```

Once the above are set, you can execute the following commands to provision services in your Aiven project

```
terraform init

terraform plan

terraform apply 
  -var="aiven_api_token=$TOKEN" \
  -var="bootstrap_servers=$BOOTSTRAP_SERVERS" \
  -var="aws_account_id=$AWS_ACCOUNT_ID" \
  -var="aws_vpc_id=$AWS_VPC_ID"
  -var="vpc_cidr_range=$CIDR_RANGE"

```