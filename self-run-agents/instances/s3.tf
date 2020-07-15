resource "aws_s3_bucket" "token" {
  bucket = "cncf-envoy-token"
  acl    = "private"

  tags = {
    Environment = "Production"
  }
}

resource "aws_s3_bucket" "build-cache" {
  bucket = "envoy-ci-build-cache"
  acl    = "private"

  tags = {
    Environment = "Production"
  }

  lifecycle_rule {
    id      = "all"
    enabled = true
    prefix  = ""

    expiration {
      days = 10
    }
  }
}
