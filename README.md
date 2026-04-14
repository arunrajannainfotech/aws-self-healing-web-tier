# aws-self-healing-web-tier
Prerequisites:
Terraform installed
AWS CLI installed
AWS credentials configured
A local copy of terraform.tfvars created from terraform.tfvars.example

1. Clone the repository
git clone <your-repo-url>
cd terraform-aws-self-healing-web-tier
https://github.com/arunrajannainfotech/aws-self-healing-web-tier.git

2. Create your variable file
cp terraform.tfvars.example terraform.tfvars

3. Initialise Terraform
terraform init

4. Validate the configuration
terraform validate

5. Run a plan
terraform plan

6. Apply
terraform apply

7. Get the ALB DNS name
terraform output alb_dns_name

-Open the returned DNS name in a browser using http://
-default web page is served by NGINX

8. To remove all provisioned resources
terraform destroy