# PostgreSQL DB component (RDS) #

### AWS Resources ###
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/pg_db.png "PostgreSQL DB")

### Notes ###
* State file, outputs, and version are saved in S3 bucket
* Use terraform_remote_state to get VPC state
* Using <b>count</b> as "if-else" conditions
* Optional public (NAT GW, subnets, router, RTAs) or VPC private subnet
* Public or private subnet groups
* terragrunt.hcl with link to "root" terragrunt.hcl file 

### The "local" terragrunt.hcl file ###
```hcl
include {
  path = find_in_parent_folders()
}
```

### The "root" terragrunt.hcl file ###
```hcl
# Configure Terragrunt to automatically store tfstate files in S3
remote_state {
  backend = "s3"
  config = {
    bucket        = "infra-comp-bucket-serg239"
    key           = "${path_relative_to_include()}/terraform.tfstate"
    region        = "us-west-1"
    encrypt       = true
    dynamodb_table = "infra-comp"
  }
}
```

### Steps to deploy and destroy the component ###
```bash
$ terragrunt init
$ terragrunt validate
$ terragrunt plan -out=2020_02_10.tfplan -input=false -lock=true

$ terragrunt apply 2020_02_10.tfplan
Outputs:
database-address = pg-db.cuisely4kovk.us-west-1.rds.amazonaws.com
database-port = 5432

$ terragrunt destroy
```
