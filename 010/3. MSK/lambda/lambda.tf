data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_function.py"
  output_path = "${path.module}/src/lambda_function.zip"
}

resource "aws_lambda_function" "function" {
  function_name = "msk-order-consumer"
  runtime       = "python3.12"
  handler       = "lambda_function.handler"
  role          = aws_iam_role.function.arn

  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256

  memory_size = 256
  timeout     = 60

  environment {
    variables = {
      AWS_REGION_NAME     = var.region
      DYNAMODB_TABLE_NAME = var.table_name
    }
  }
}

resource "aws_lambda_event_source_mapping" "msk" {
  event_source_arn  = var.msk_cluster_arn
  function_name     = aws_lambda_function.function.arn
  topics            = ["order-events"]
  starting_position = "TRIM_HORIZON"
  batch_size        = 100
}
