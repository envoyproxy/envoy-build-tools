# Creates an IAM Role where instances themselves can then set instance
# protection on themselves.

data "aws_iam_policy_document" "asg_scale_in_protection" {
  statement {
    actions = [
      "autoscaling:SetInstanceProtection",
    ]

    resources = [
      "arn:aws:autoscaling:*:${var.aws_account_id}:autoScalingGroup:*:autoScalingGroupName/${local.asg_name}",
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
  policy = data.aws_iam_policy_document.asg_scale_in_protection.json
}

resource "aws_iam_instance_profile" "asg_iam_instance_profile" {
  name = "${var.ami_prefix}_${var.azp_pool_name}_IProfile"
  role = aws_iam_role.asg_iam_role.name
}