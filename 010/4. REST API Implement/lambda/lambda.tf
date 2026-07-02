resource "aws_lambda_layer_version" "env" {
  layer_name          = "${var.prefix}-worldschool-env-layer"
  filename            = "${path.module}/layer/layer.zip"
  source_code_hash    = filebase64sha256("${path.module}/layer/layer.zip")
  compatible_runtimes = ["python3.14"]
}

data "archive_file" "function" {
  type        = "zip"
  source_file = "${path.module}/src/lambda_code.py"
  output_path = "${path.module}/src/lambda_code.zip"
}

resource "aws_lambda_function" "function" {
  function_name = "${var.prefix}-worldschool-management"
  runtime       = "python3.14"
  handler       = "lambda_code.lambda_handler"
  role          = aws_iam_role.function.arn
  layers           = [aws_lambda_layer_version.env.arn]

  filename         = data.archive_file.function.output_path
  source_code_hash = data.archive_file.function.output_base64sha256
}