//versions
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

//provider

provider "aws" {
  region = var.aws_region
}

//networking

module "networking" {
  source = "./modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

//compute

module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  web_subnet_ids        = module.networking.private_subnet_ids
  alb_security_group_id = module.networking.alb_security_group_id
  web_security_group_id = module.networking.web_security_group_id

  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}