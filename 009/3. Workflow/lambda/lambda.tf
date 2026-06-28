data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/app/lambda_code.py"
  output_path = "${path.module}/app/lambda_code.zip"
}

resource "aws_lambda_function" "transform" {
  function_name = "workflow-transform"
  handler       = "lambda_code.lambda_handler"
  runtime       = "python3.12"
  role          = aws_iam_role.lambda_role.arn
  timeout       = 60

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = "workflow-output"
    }
  }
}