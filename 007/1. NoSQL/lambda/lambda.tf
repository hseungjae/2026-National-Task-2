data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_code.py"
  output_path = "${path.module}/src/lambda_code.zip"
}

resource "aws_lambda_function" "transform" {
  function_name = "${var.prefix}-reservation-audit"
  handler       = "lambda_code.handler"
  runtime       = "python3.13"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 30

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_event_source_mapping" "reservation_ddb_trigger" {
  event_source_arn  = var.reserve_ddb_arn
  function_name     = aws_lambda_function.transform.arn
  starting_position = "LATEST"
  enabled           = true
}