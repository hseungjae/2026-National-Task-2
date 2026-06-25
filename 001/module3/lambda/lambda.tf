# 모듈 루트의 lambda_transform.py 를 zip 으로 패키징
data "archive_file" "transform_zip" {
  type        = "zip"
  source_file = "${path.module}/../lambda_transform.py"
  output_path = "${path.module}/lambda_transform.zip"
}

# 데이터 정제 Lambda 함수 (Runtime python3.14)
resource "aws_lambda_function" "transform" {
  function_name    = var.function_name
  role             = var.role_arn
  handler          = "lambda_transform.lambda_handler"
  runtime          = "python3.14"
  filename         = data.archive_file.transform_zip.output_path
  source_code_hash = data.archive_file.transform_zip.output_base64sha256
  timeout          = 30
}
