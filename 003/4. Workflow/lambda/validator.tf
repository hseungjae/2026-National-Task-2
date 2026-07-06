data "archive_file" "validator" {
  type        = "zip"
  source_dir  = "${path.module}/code/validator"
  output_path = "${path.module}/code/validator.zip"
}

resource "aws_lambda_function" "validator" {
  function_name = "${var.prefix}-order-validator"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  filename         = data.archive_file.validator.output_path
  source_code_hash = data.archive_file.validator.output_base64sha256
}
