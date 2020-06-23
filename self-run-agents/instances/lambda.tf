resource "aws_lambda_function" "dereg_lambda" {
  filename      = "lambda-dereg.zip"
  function_name = "azp_dereg_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  memory_size = 512
  timeout     = 180

  source_code_hash = filebase64sha256("lambda-dereg.zip")

  environment {
    variables = {
      AZP_USER  = "cncf"
      AZP_TOKEN = var.azp_token
    }
  }
}

resource "aws_lambda_function" "cleanup_lambda" {
  filename      = "lambda-cleanup.zip"
  function_name = "ami_cleanup_lambda"
  role          = aws_iam_role.cleanup_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  memory_size = 512
  timeout     = 180

  source_code_hash = filebase64sha256("lambda-cleanup.zip")
}
