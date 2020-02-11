# Web server component (EC2 instances) #

### AWS Resources ###
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-comp/images/web.jpg "PostgreSQL DB")

### Notes ###
* State file, outputs, and version are saved in S3 bucket
* Use terraform_remote_state to get VPC and DB states
* Using <b>count</b> as "if-else" conditions
* Load Balancer
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
aws_service_elb_public_dns = infra-web-elb-1961265067.us-west-1.elb.amazonaws.com

$ terragrunt destroy
```
