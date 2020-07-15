# Creates an IAM Role where instances themselves can then detach themselves from ASG.
data "aws_iam_policy_document" "asg_detach_instances" {
  statement {
    actions = [
      "autoscaling:DetachInstances"
    ]

    resources = [
      "arn:aws:autoscaling:*:${var.aws_account_id}:autoScalingGroup:*:autoScalingGroupName/${local.asg_name}",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.bazel_cache_bucket}",
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "${var.cache_prefix}/*",
      ]
    }
  }
  statement {
    actions = [
      "s3:*Object"
    ]
    resources = [
      "arn:aws:s3:::${var.bazel_cache_bucket}/${var.cache_prefix}/*",
    ]
  }
}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "asg_iam_role" {
  name               = "${var.ami_prefix}_${var.azp_pool_name}_IAMRole"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy" "asg_iam_role_policy" {
  name   = "${var.ami_prefix}_${var.azp_pool_name}_IAMRolePolicy"
  role   = aws_iam_role.asg_iam_role.id
  policy = data.aws_iam_policy_document.asg_detach_instances.json
}

resource "aws_iam_instance_profile" "asg_iam_instance_profile" {
  name = "${var.ami_prefix}_${var.azp_pool_name}_IProfile"
  role = aws_iam_role.asg_iam_role.name
}

# Creates an IAM Role where instances can get token and associate with running IAM profile.
data "aws_iam_policy_document" "init_permissions" {
  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "arn:aws:s3:::cncf-envoy-token/azp_token",
    ]
  }

  statement {
    actions = [
      "ec2:ReplaceIamInstanceProfileAssociation"
    ]

    resources = [
      "*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ARN"
      values   = ["$${ec2:SourceInstanceARN}"]
    }
  }

  statement {
    actions = [
      "iam:PassRole"
    ]

    resources = [
      aws_iam_role.asg_iam_role.arn
    ]
  }

  statement {
    actions = [
      "ec2:DescribeIamInstanceProfileAssociations"
    ]

    resources = [
      "*",
    ]
  }

}

resource "aws_iam_role" "asg_init_iam_role" {
  name               = "${var.ami_prefix}_${var.azp_pool_name}_init_IAMRole"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy" "asg_init_iam_role_policy" {
  name   = "${var.ami_prefix}_${var.azp_pool_name}_init_IAMRolePolicy"
  role   = aws_iam_role.asg_init_iam_role.id
  policy = data.aws_iam_policy_document.init_permissions.json
}

resource "aws_iam_instance_profile" "asg_init_iam_instance_profile" {
  name = "${var.ami_prefix}_${var.azp_pool_name}_init_IProfile"
  role = aws_iam_role.asg_init_iam_role.name
}
