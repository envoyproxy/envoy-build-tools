provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

module "x64-large-build-pool" {
  source = "./azp-build-asg"

  ami_prefix           = "envoy-azp-x64-large"
  aws_account_id       = "457956385456"
  azp_pool_name        = "x64-large"
  azp_token            = var.azp_token
  disk_size_gb         = 2000
  idle_instances_count = 1
  instance_type        = "r5.8xlarge"

  providers = {
    aws = aws
  }
}

module "arm-build-pool" {
  source = "./azp-build-asg"

  ami_prefix           = "envoy-azp-arm-large"
  aws_account_id       = "457956385456"
  azp_pool_name        = "arm-large"
  azp_token            = var.azp_token
  disk_size_gb         = 500
  idle_instances_count = 1
  instance_type        = "r6g.2xlarge"

  providers = {
    aws = aws
  }
}
