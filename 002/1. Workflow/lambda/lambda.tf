data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "archive_file" "score_function" {
  type        = "zip"
  source_file = "${path.module}/score-function/index.py"
  output_path = "${path.module}/score-function.zip"
}

data "archive_file" "trigger_function" {
  type        = "zip"
  source_file = "${path.module}/trigger-function/index.py"
  output_path = "${path.module}/trigger-function.zip"
}

resource "aws_lambda_function" "score_function" {
  filename         = data.archive_file.score_function.output_path
  source_code_hash = data.archive_file.score_function.output_base64sha256
  function_name    = "wsc2026-student-score-function"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      S3_BUCKET = var.s3_bucket_name
      DDB_TABLE = var.dynamodb_table_name
    }
  }

  tags = { Name = "wsc2026-student-score-function" }
}

resource "aws_lambda_function" "trigger_function" {
  filename         = data.archive_file.trigger_function.output_path
  source_code_hash = data.archive_file.trigger_function.output_base64sha256
  function_name    = "wsc2026-student-trigger"
  role             = var.lambda_trigger_role_arn
  handler          = "index.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      STATE_MACHINE_ARN = "arn:aws:states:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stateMachine:wsc2026-student-score-workflow"
    }
  }

  tags = { Name = "wsc2026-student-trigger" }
}
