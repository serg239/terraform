# Project #

## infra-ec2 ## 
Create simple Web server on EC2 instance.<br>

AWS Resources: 
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-ec2/graph/infra-ec2.png "AWS Resources")

Notes:
1. Data source for user_data shell script:
```bash  
  #!/bin/bash
  echo "Hello, World!" > index.html
  nohup busybox httpd -f -p "${server-port}" &
```

2. The graph (as .png file) is in the infra-ec2/graph directory

To create graph and convet it to .pdf or .png files:
```bash
  $ terraform graph > 2020_02_09_plan.dot
  $ dot -Tpdf 2020_02_09_plan.dot -o 2020_02_09_plan.pdf
  $ dot -Tpng 2020_02_09_plan.dot -o 2020_02_09_plan.png
```  

Terraform plan: 
![alt text](https://github.com/serg239/terraform/blob/master/aws/infra-ec2/graph/2020_02_09_plan.png "Terraform Plan")

## Steps to run the project ##

```bash
$ terrafotrm init
$ terraform validate
$ terraform plan -out=2020_02_09.tfplan -input=false -lock=true
$ terraform apply 2020_02_09.tfplan

$ terraform destroy
```

## License

This code is released under the MIT License. See LICENSE.txt.
