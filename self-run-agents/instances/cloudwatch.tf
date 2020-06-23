resource "aws_cloudwatch_event_rule" "every_day" {
  name                = "every-day"
  description         = "Fires once every day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "cleanup_every_day" {
  rule      = aws_cloudwatch_event_rule.every_day.name
  target_id = "cleanup_amis_daily"
  arn       = aws_lambda_function.cleanup_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_cleanup" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day.arn
}

resource "aws_cloudwatch_event_rule" "ec2_terminate" {
  name        = "ec2-terminate"
  description = "EC2 instance terminate"

  event_pattern = <<PATTERN
{
  "source": [
    "aws.ec2"
  ],
  "detail-type": [
    "EC2 Instance State-change Notification"
  ],
  "detail": {
    "state": [
      "terminated"
    ]
  }
}
PATTERN
}

resource "aws_cloudwatch_event_target" "ec2_terminate_dereg" {
  rule      = aws_cloudwatch_event_rule.ec2_terminate.name
  target_id = "azp_dereg_lambda"
  arn       = aws_lambda_function.dereg_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_dereg" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dereg_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_terminate.arn
}
