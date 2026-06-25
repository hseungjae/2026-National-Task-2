# 모듈 루트의 lambda_api_handler.py 를 zip 으로 패키징
data "archive_file" "api_handler_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_api_handler.py"
  output_path = "${path.module}/lambda_api_handler.zip"
}

# API Gateway 요청을 처리하는 Lambda 함수 (Runtime python3.14)
resource "aws_lambda_function" "api_handler" {
  function_name    = var.function_name
  role             = var.role_arn
  handler          = "lambda_api_handler.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.api_handler_zip.output_path
  source_code_hash = data.archive_file.api_handler_zip.output_base64sha256
  timeout          = 30
}
