# ── EventBridge 실행 역할 (Step Functions 시작) ──────────────────────────────
resource "aws_iam_role" "eventbridge_role" {
  name = "wsc2026-eventbridge-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "events.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "eventbridge_policy" {
  name = "start-stepfunctions"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["states:StartExecution"]
      Resource = var.state_machine_arn
    }]
  })
}

# ── EventBridge Rule (S3 PutObject → Step Functions) ─────────────────────────
resource "aws_cloudwatch_event_rule" "s3_trigger" {
  name        = var.rule_name
  description = "S3 PutObject -> Step Functions"
  state       = "ENABLED"

  event_pattern = jsonencode({
    source        = ["aws.s3"]
    "detail-type" = ["Object Created"]
    detail = {
      bucket = { name = [var.bucket_name] }
      reason = ["PutObject"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sf" {
  rule     = aws_cloudwatch_event_rule.s3_trigger.name
  arn      = var.state_machine_arn
  role_arn = aws_iam_role.eventbridge_role.arn
}
