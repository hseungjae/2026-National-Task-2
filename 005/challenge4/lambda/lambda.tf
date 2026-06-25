data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/function.py"
  output_path = "${path.module}/function.zip"
}

resource "aws_lambda_function" "this" {
  function_name    = "wsc-rest-function"
  role             = var.lambda_role_arn
  handler          = "function.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
  timeout          = 30

  environment {
    variables = {
      TABLE_NAME = var.table_name
    }
  }

  tags = { Name = "wsc-rest-function" }
}
