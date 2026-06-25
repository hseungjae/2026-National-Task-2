resource "aws_cloudwatch_event_rule" "sg_change" {
  name           = "wsc2026-sg-change-rule"
  description    = "Detect EC2 AuthorizeSecurityGroupIngress via CloudTrail"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AuthorizeSecurityGroupIngress"]
    }
  })

  tags = { Name = "wsc2026-sg-change-rule" }
}

resource "aws_cloudwatch_event_target" "sg_change" {
  rule           = aws_cloudwatch_event_rule.sg_change.name
  event_bus_name = "default"
  target_id      = "wsc2026-sg-remediation"
  arn            = var.lambda_arns["sg_remediation"]
}

resource "aws_lambda_permission" "sg_change" {
  statement_id  = "AllowEventBridgeInvokeSG"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_names["sg_remediation"]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sg_change.arn
}

resource "aws_cloudwatch_event_rule" "role_change" {
  name           = "wsc2026-role-change-rule"
  description    = "Detect EC2 IAM Role change via CloudTrail"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["AssociateIamInstanceProfile", "ReplaceIamInstanceProfileAssociation"]
    }
  })

  tags = { Name = "wsc2026-role-change-rule" }
}

resource "aws_cloudwatch_event_target" "role_change" {
  rule           = aws_cloudwatch_event_rule.role_change.name
  event_bus_name = "default"
  target_id      = "wsc2026-role-remediation"
  arn            = var.lambda_arns["role_remediation"]
}

resource "aws_lambda_permission" "role_change" {
  statement_id  = "AllowEventBridgeInvokeRole"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_names["role_remediation"]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.role_change.arn
}

resource "aws_cloudwatch_event_rule" "ec2_terminate" {
  name           = "wsc2026-ec2-terminate-rule"
  description    = "Detect EC2 instance termination"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
    detail = {
      state = ["terminated"]
    }
  })

  tags = { Name = "wsc2026-ec2-terminate-rule" }
}

resource "aws_cloudwatch_event_target" "ec2_terminate" {
  rule           = aws_cloudwatch_event_rule.ec2_terminate.name
  event_bus_name = "default"
  target_id      = "wsc2026-ec2-terminate-alert"
  arn            = var.lambda_arns["ec2_terminate_alert"]
}

resource "aws_lambda_permission" "ec2_terminate" {
  statement_id  = "AllowEventBridgeInvokeTerminate"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_names["ec2_terminate_alert"]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_terminate.arn
}

resource "aws_cloudwatch_event_rule" "ec2_type_change" {
  name           = "wsc2026-ec2-type-change-rule"
  description    = "Detect EC2 instance type change via CloudTrail"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["ec2.amazonaws.com"]
      eventName   = ["ModifyInstanceAttribute"]
    }
  })

  tags = { Name = "wsc2026-ec2-type-change-rule" }
}

resource "aws_cloudwatch_event_target" "ec2_type_change" {
  rule           = aws_cloudwatch_event_rule.ec2_type_change.name
  event_bus_name = "default"
  target_id      = "wsc2026-ec2-type-remediation"
  arn            = var.lambda_arns["ec2_type_remediation"]
}

resource "aws_lambda_permission" "ec2_type_change" {
  statement_id  = "AllowEventBridgeInvokeTypeChange"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_names["ec2_type_remediation"]
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_type_change.arn
}
