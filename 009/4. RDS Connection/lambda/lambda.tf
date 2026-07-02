data "archive_file" "rds_query" {
  type        = "zip"
  source_file = "${path.module}/app/lambda_code.py"
  output_path = "${path.module}/app/lambda_code.zip"
}

resource "aws_lambda_function" "transform" {
  function_name = "rds-query-function"
  handler       = "lambda_code.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn

  filename         = data.archive_file.rds_query.output_path
  source_code_hash = data.archive_file.rds_query.output_base64sha256

  environment {
    variables = {
      CLUSTER_ARN = var.rds_arn
      SECRET_ARN  = var.secret_arn
      DB_NAME     = "appdb"
    }
  }
}