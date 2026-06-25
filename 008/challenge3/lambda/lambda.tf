data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../../challenge3/remediate_security_group.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "remediate" {
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  function_name    = "skills-ceh-remediate-fn"
  role             = var.role_arn
  handler          = "remediate_security_group.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      PROTECTED_SECURITY_GROUP_ID = var.protected_sg_id
      SNS_TOPIC_ARN               = var.topic_arn
    }
  }

  tags = { Name = "skills-ceh-remediate-fn" }
}
