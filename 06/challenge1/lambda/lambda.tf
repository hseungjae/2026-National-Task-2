data "archive_file" "rotate" {
  type        = "zip"
  source_file = "${path.module}/rotate/handler.py"
  output_path = "${path.module}/rotate.zip"
}

data "archive_file" "request" {
  type        = "zip"
  source_file = "${path.module}/request/handler.py"
  output_path = "${path.module}/request.zip"
}

resource "aws_lambda_function" "rotate" {
  filename         = data.archive_file.rotate.output_path
  source_code_hash = data.archive_file.rotate.output_base64sha256
  function_name    = "gj2026-cdn-rotate"
  role             = var.role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.14"
  timeout          = 30
  memory_size      = 512

  environment {
    variables = {
      S3_BUCKET = var.bucket_name
    }
  }

  tags = { Name = "gj2026-cdn-rotate" }
}

resource "aws_lambda_function_url" "rotate" {
  function_name      = aws_lambda_function.rotate.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_permission" "rotate_url_public" {
  statement_id           = "FunctionURLAllowPublicAccess"
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.rotate.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

resource "aws_lambda_function" "request" {
  filename         = data.archive_file.request.output_path
  source_code_hash = data.archive_file.request.output_base64sha256
  function_name    = "gj2026-cdn-request"
  role             = var.role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.14"
  timeout          = 5
  memory_size      = 128
  publish          = true

  tags = { Name = "gj2026-cdn-request" }
}

resource "aws_lambda_function" "response" {
  filename         = data.archive_file.request.output_path
  source_code_hash = data.archive_file.request.output_base64sha256
  function_name    = "gj2026-cdn-response"
  role             = var.role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.14"
  timeout          = 30
  memory_size      = 128
  publish          = true

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  tags = { Name = "gj2026-cdn-response" }
}
