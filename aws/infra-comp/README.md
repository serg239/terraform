# infra-comp project #
---
### Create S3 bucket, custom VPC, DB cluster, and Web server ###

### Project Components ###
* [S3 bucket](https://github.com/serg239/terraform/blob/master/aws/infra-comp/global/s3 "S3 bucket")
* [Custom VPC](https://github.com/serg239/terraform/blob/master/aws/infra-comp/dev/vpc "Custom VPC")
* [PostgreSQL DB (RDS)](https://github.com/serg239/terraform/blob/master/aws/infra-comp/dev/db/postgres "PostgreSQL DB (RDS)")
* [Web server (EC2)](https://github.com/serg239/terraform/blob/master/aws/infra-comp/dev/services/frontend "Web server (EC2)")

### Notes ###
* State files of the components are isolated and saved in S3 bucket
* Save outputs of state files into S3 
* Using terraform_remote_state data source to read data from the VPC, DB and EC2 state files
* Configute public/private subnets in variables
* Load balancer and security groups
* Use count as "if-else" statements
* Switch user_data betweeh EC2 instances in AZs

### File layout ###
Development environment:
```bash
$ tree
+-- dev
¦   +-- db
¦   ¦   L-- postgres
¦   ¦       +-- main.tf
¦   ¦       +-- outputs.tf
¦   ¦       +-- terraform.tfvars
¦   ¦       +-- terragrunt.hcl
¦   ¦       L-- variables.tf
¦   +-- services
¦   ¦   L-- frontend
¦   ¦       +-- main.tf
¦   ¦       +-- nginx_blue.sh
¦   ¦       +-- nginx_green.sh
¦   ¦       +-- outputs.tf
¦   ¦       +-- terraform.tfvars
¦   ¦       +-- terragrunt.hcl
¦   ¦       +-- user_data.sh
¦   ¦       +-- variables.tf
¦   L-- vpc
¦       +-- main.tf
¦       +-- outputs.tf
¦       +-- terraform.tfvars
¦       +-- terragrunt.hcl
¦       L-- variables.tf
+-- global
¦   L-- s3
¦       +-- main.tf
¦       +-- outputs.tf
¦       +-- terraform.tfvars
¦       L-- variables.tf
L-- terragrunt.hcl
```

### Steps to run the project ###

1. Deploy S3 bucket 
```bash
$ cd global/s3
$ terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true
$ terragrunt apply 2020_02_10.tfplan
```

2. Deploy custom VPC
```bash
$ cd ../../dev/vpc
$ terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true
$ terragrunt apply 2020_02_10.tfplan

Outputs:
azs = [
  "us-west-1b",
  "us-west-1c",
]
public-subnets = [
  "subnet-0254be9c474390bdf",
  "subnet-09e382ee5115ffba9",
]
vpc-id = vpc-09521e538bb1c4d0a
vpc-igw = igw-03aef3e5592bac823
. . .
```

3. Deploy PostgreSQL DB (RDS)
```bash
$ cd ../db/postgres
$ terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true
$ terragrunt apply 2020_02_10.tfplan

Outputs:
database-address = pg-db.cuisely4kovk.us-west-1.rds.amazonaws.com
database-port = 5432
```

4. Deploy WEB cluster (EC2 instances)
```bash
$ cd ../../services/frontend
$ terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true
$ terragrunt apply 2020_02_10.tfplan

Outputs:
aws_service_elb_public_dns = infra-web-elb-1961265067.us-west-1.elb.amazonaws.com
```

## Expected results ##

### Web pages ###

http://infra-web-elb-1961265067.us-west-1.elb.amazonaws.com:80

1. Web page from the Web instance in Availability Zone 1
  
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/web_azs1.jpg "Web page from AZ1")

<b>Reload the page</b>

2. Web page from the Web instance in Availability Zone 2
  
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/web_azs2.jpg "Web page from AZ2")

### Connect to PostgreSQL database by using pgAdmin ###

![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/db.jpg "Connect to DB")
