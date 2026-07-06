data "archive_file" "payment" {
  type        = "zip"
  source_dir  = "${path.module}/code/payment"
  output_path = "${path.module}/code/payment.zip"
}

resource "aws_lambda_function" "payment" {
  function_name = "${var.prefix}-payment-processor"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.13"
  timeout       = 30

  filename         = data.archive_file.payment.output_path
  source_code_hash = data.archive_file.payment.output_base64sha256
}
