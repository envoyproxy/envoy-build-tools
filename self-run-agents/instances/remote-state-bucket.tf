resource "aws_s3_bucket" "remote-state-bucket" {
  bucket = "envoy-build-tf-remote-state"
  acl    = "private"

  tags = {
    Environment = "Production"
  }
}

terraform {
  backend "s3" {
    bucket = "envoy-build-tf-remote-state"
    key    = "github/envoyproxy/envoy-build-tools/terraform.tfstate"
    region = "us-east-1"
  }

  required_version = ">= 0.12"
}