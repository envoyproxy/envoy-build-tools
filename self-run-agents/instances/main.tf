provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

module "x64-large-build-pool" {
  source = "./azp-build-asg"

  ami_prefix                 = "envoy-azp-x64-large"
  aws_account_id             = "457956385456"
  azp_pool_name              = "x64-large"
  azp_token                  = var.azp_token
  disk_size_gb               = 2000
  guaranteed_instances_count = 2
  instance_type              = "r5.4xlarge"

  sns_lifecycle_arn     = aws_sns_topic.lifecycle_updates.arn
  sns_lifecyle_role_arn = aws_iam_role.asg_sns_role.arn

  providers = {
    aws = aws
  }
}

module "arm-build-pool" {
  source = "./azp-build-asg"

  ami_prefix                 = "envoy-azp-arm-large"
  aws_account_id             = "457956385456"
  azp_pool_name              = "arm-large"
  azp_token                  = var.azp_token
  disk_size_gb               = 200
  guaranteed_instances_count = 2
  instance_type              = "m6g.4xlarge"

  sns_lifecycle_arn     = aws_sns_topic.lifecycle_updates.arn
  sns_lifecyle_role_arn = aws_iam_role.asg_sns_role.arn

  providers = {
    aws = aws
  }
}
