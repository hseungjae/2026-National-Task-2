data "archive_file" "recovery" {
  type        = "zip"
  source_file = "${path.module}/recovery/handler.py"
  output_path = "${path.module}/recovery.zip"
}

data "archive_file" "updater" {
  type        = "zip"
  source_file = "${path.module}/updater/handler.py"
  output_path = "${path.module}/updater.zip"
}

resource "aws_cloudwatch_log_group" "recovery" {
  name              = "/aws/lambda/gj2026-event-recovery"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "updater" {
  name              = "/aws/lambda/gj2026-event-updater"
  retention_in_days = 7
}

resource "aws_lambda_function" "recovery" {
  filename         = data.archive_file.recovery.output_path
  source_code_hash = data.archive_file.recovery.output_base64sha256
  function_name    = "gj2026-event-recovery"
  role             = var.recovery_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 256

  environment {
    variables = {
      INSTANCE_ID = var.instance_id
    }
  }

  depends_on = [aws_cloudwatch_log_group.recovery]

  tags = { Name = "gj2026-event-recovery" }
}

resource "aws_lambda_function" "updater" {
  filename         = data.archive_file.updater.output_path
  source_code_hash = data.archive_file.updater.output_base64sha256
  function_name    = "gj2026-event-updater"
  role             = var.updater_role_arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  memory_size      = 256

  environment {
    variables = {
      INSTANCE_ID = var.instance_id
    }
  }

  depends_on = [aws_cloudwatch_log_group.updater]

  tags = { Name = "gj2026-event-updater" }
}
