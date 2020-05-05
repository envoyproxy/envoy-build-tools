#########################################################################################
# Permissions for the Lambda to Deregister Instances.                                   #
#########################################################################################

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

data "aws_iam_policy_document" "lambda_ec2_permissions" {
  statement {
    actions = [
      # Get the Tags to identify the Pool Name.
      "ec2:DescribeInstances",
      # Complete the lifecycle action waiting.
      "autoscaling:CompleteLifecycleAction",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "azure_dereg_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy" "log_perms" {
  name = "azure_dereg_lambda_log_perms"
  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy" "ec2_perms" {
  name = "azure_dereg_lambda_ec2_perms"
  role = aws_iam_role.lambda_role.id

  policy = data.aws_iam_policy_document.lambda_ec2_permissions.json
}

#########################################################################################
# Permissions for the ASGs to publish to the SNS Topic                                  #
#########################################################################################

data "aws_iam_policy_document" "asg_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["autoscaling.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "asg_publish_perms" {
  statement {
    actions = [
      "sns:Publish"
    ]

    resources = [aws_sns_topic.lifecycle_updates.arn]
  }
}

resource "aws_iam_role" "asg_sns_role" {
  name               = "azure_dereg_lifecycle_sns_role"
  assume_role_policy = data.aws_iam_policy_document.asg_assume_role_policy.json
}

resource "aws_iam_role_policy" "sns_perms" {
  name = "azure_lifecycle_dereg_perms"
  role = aws_iam_role.asg_sns_role.id

  policy = data.aws_iam_policy_document.asg_publish_perms.json
}