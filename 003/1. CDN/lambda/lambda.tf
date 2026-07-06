resource "local_file" "lambda_code" {
  filename = "${path.module}/src/package/lambda_code.py"
  content = templatefile("${path.module}/src/lambda_code.py.tpl", {
    bucket_name = var.bucket_name
  })
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = "${path.module}/src/package"
  output_path = "${path.module}/build/function.zip"

  depends_on = [local_file.lambda_code]
}

resource "aws_lambda_function" "book_get" {
  function_name = "${var.prefix}-resize"
  runtime       = "python3.12"
  handler       = "lambda_code.lambda_handler"
  role          = aws_iam_role.function.arn
  publish       = true
  timeout       = 30
  memory_size   = 1024

  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
}
