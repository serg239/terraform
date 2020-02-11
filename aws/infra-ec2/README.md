# Project #

## infra-ec2 - Create simple Web server in custom VPC ##

AWS Resources
-------------
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-ec2/graph/infra-ec2.png "AWS Resources")

Notes
-----
1. Data source for user_data shell script:
```bash  
  #!/bin/bash
  echo "Hello, World!" > index.html
  nohup busybox httpd -f -p "${server-port}" &
```

## Steps to run the project ##

```bash
$ terraform init
$ terraform validate
$ terraform plan -out=2020_02_09.tfplan -input=false -lock=true
$ terraform apply 2020_02_09.tfplan

$ terraform destroy
```

To create graph and convet it to .pdf or .png files:
```bash
  $ terraform graph > 2020_02_09_plan.dot
  $ dot -Tpdf 2020_02_09_plan.dot -o 2020_02_09_plan.pdf
  $ dot -Tpng 2020_02_09_plan.dot -o 2020_02_09_plan.png
```  

The .png file of the graph is in the infra-ec2/graph directory.

Terraform plan
--------------
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-ec2/graph/2020_02_09_plan.png "Terraform Plan")

## License

This code is released under the MIT License. See LICENSE.txt.
