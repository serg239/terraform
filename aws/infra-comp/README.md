# Project #

## infra-comp - Create custom VPC, DB cluster, and Web server ##

Notes
-----
* State files of the components are isolated and saved in S3 bucket
* Save outputs of state files into S3 
* Using terraform_remote_state data source to read data from the VPC, DB and EC2 state files
* Configute public/private subnets in variables
* Load balancer and security groups
* Use count as "if-else" statements
* Switch user_data betweeh EC2 instances in AZs

AWS Resources
-------------

File layout
-----------

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
