data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "archive_file" "sensor_consumer" {
  type        = "zip"
  source_file = "${path.module}/sensor-consumer/index.py"
  output_path = "${path.module}/sensor-consumer.zip"
}

data "archive_file" "alert_consumer" {
  type        = "zip"
  source_file = "${path.module}/alert-consumer/index.py"
  output_path = "${path.module}/alert-consumer.zip"
}

resource "aws_security_group" "lambda" {
  name        = "wsc2026-lambda-msk-sg"
  description = "Security group for MSK Lambda consumers"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "wsc2026-lambda-msk-sg" }
}

resource "aws_security_group_rule" "msk_from_lambda" {
  type                     = "ingress"
  from_port                = 9098
  to_port                  = 9098
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = var.msk_sg_id
  description              = "Allow Lambda to MSK IAM"
}

resource "aws_lambda_function" "sensor_consumer" {
  filename         = data.archive_file.sensor_consumer.output_path
  source_code_hash = data.archive_file.sensor_consumer.output_base64sha256
  function_name    = "wsc2026-sensor-consumer"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.14"
  timeout          = 300

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      DDB_TABLE       = var.dynamodb_table
      ALERT_TOPIC_ARN = var.alert_topic_arn
    }
  }

  tags = { Name = "wsc2026-sensor-consumer" }
}

resource "aws_lambda_event_source_mapping" "sensor_raw_trigger" {
  event_source_arn  = var.msk_cluster_arn
  function_name     = aws_lambda_function.sensor_consumer.arn
  topics            = ["wsc2026-sensor-raw"]
  starting_position = "LATEST"
}

resource "aws_lambda_function" "alert_consumer" {
  filename         = data.archive_file.alert_consumer.output_path
  source_code_hash = data.archive_file.alert_consumer.output_base64sha256
  function_name    = "wsc2026-sensor-alert-consumer"
  role             = var.lambda_role_arn
  handler          = "index.handler"
  runtime          = "python3.14"
  timeout          = 300

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  environment {
    variables = {
      SNS_TOPIC_ARN = var.alert_topic_arn
      S3_BUCKET     = var.s3_bucket_name
    }
  }

  tags = { Name = "wsc2026-sensor-alert-consumer" }
}

resource "aws_lambda_event_source_mapping" "sensor_alert_trigger" {
  event_source_arn  = var.msk_cluster_arn
  function_name     = aws_lambda_function.alert_consumer.arn
  topics            = ["wsc2026-sensor-alert"]
  starting_position = "LATEST"
}
