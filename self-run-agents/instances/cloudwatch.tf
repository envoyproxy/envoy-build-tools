resource "aws_cloudwatch_event_rule" "every_day" {
  name = "every-day"
  description = "Fires once every day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "cleanup_every_day" {
  rule = aws_cloudwatch_event_rule.every_day.name
  target_id = "cleanup_amis_daily"
  arn = aws_lambda_function.cleanup_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_check_foo" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cleanup_lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.every_day.arn
}