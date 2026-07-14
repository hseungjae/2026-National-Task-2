data "archive_file" "sg_remediation" {
  type        = "zip"
  source_file = "${path.module}/sg-remediation/index.py"
  output_path = "${path.module}/sg-remediation.zip"
}

data "archive_file" "role_remediation" {
  type        = "zip"
  source_file = "${path.module}/role-remediation/index.py"
  output_path = "${path.module}/role-remediation.zip"
}

data "archive_file" "ec2_terminate_alert" {
  type        = "zip"
  source_file = "${path.module}/ec2-terminate-alert/index.py"
  output_path = "${path.module}/ec2-terminate-alert.zip"
}

data "archive_file" "ec2_type_remediation" {
  type        = "zip"
  source_file = "${path.module}/ec2-type-remediation/index.py"
  output_path = "${path.module}/ec2-type-remediation.zip"
}

data "archive_file" "ec2_stop_remediation" {
  type        = "zip"
  source_file = "${path.module}/ec2-stop-remediation/index.py"
  output_path = "${path.module}/ec2-stop-remediation.zip"
}

data "archive_file" "tag_alert" {
  type        = "zip"
  source_file = "${path.module}/tag-alert/index.py"
  output_path = "${path.module}/tag-alert.zip"
}

resource "aws_lambda_function" "sg_remediation" {
  filename         = data.archive_file.sg_remediation.output_path
  source_code_hash = data.archive_file.sg_remediation.output_base64sha256
  function_name    = "wsc2026-sg-remediation"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      SNS_TOPIC_ARN     = var.topic_arn
      SECURITY_GROUP_ID = var.sg_id
    }
  }

  tags = { Name = "wsc2026-sg-remediation" }
}

resource "aws_lambda_function" "role_remediation" {
  filename         = data.archive_file.role_remediation.output_path
  source_code_hash = data.archive_file.role_remediation.output_base64sha256
  function_name    = "wsc2026-role-remediation"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      SNS_TOPIC_ARN = var.topic_arn
      INSTANCE_ID   = var.instance_id
      ROLE_NAME     = "wsc2026-event-ec2-role"
    }
  }

  tags = { Name = "wsc2026-role-remediation" }
}

resource "aws_lambda_function" "ec2_terminate_alert" {
  filename         = data.archive_file.ec2_terminate_alert.output_path
  source_code_hash = data.archive_file.ec2_terminate_alert.output_base64sha256
  function_name    = "wsc2026-ec2-terminate-alert"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = var.topic_arn
    }
  }

  tags = { Name = "wsc2026-ec2-terminate-alert" }
}

resource "aws_lambda_function" "ec2_type_remediation" {
  filename         = data.archive_file.ec2_type_remediation.output_path
  source_code_hash = data.archive_file.ec2_type_remediation.output_base64sha256
  function_name    = "wsc2026-ec2-type-remediation"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 300

  environment {
    variables = {
      SNS_TOPIC_ARN = var.topic_arn
      INSTANCE_ID   = var.instance_id
      INSTANCE_TYPE = var.instance_type
    }
  }

  tags = { Name = "wsc2026-ec2-type-remediation" }
}

resource "aws_lambda_function" "ec2_stop_remediation" {
  filename         = data.archive_file.ec2_stop_remediation.output_path
  source_code_hash = data.archive_file.ec2_stop_remediation.output_base64sha256
  function_name    = "wsc2026-ec2-stop-remediation"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 60
  memory_size      = 512

  environment {
    variables = {
      SNS_TOPIC_ARN = var.topic_arn
    }
  }

  tags = { Name = "wsc2026-ec2-stop-remediation" }
}

resource "aws_lambda_function" "tag_alert" {
  filename         = data.archive_file.tag_alert.output_path
  source_code_hash = data.archive_file.tag_alert.output_base64sha256
  function_name    = "wsc2026-tag-alert"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.12"
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = var.topic_arn
    }
  }

  tags = { Name = "wsc2026-tag-alert" }
}
