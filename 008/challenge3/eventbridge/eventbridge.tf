resource "aws_cloudwatch_event_rule" "sg_change" {
  name           = "skills-ceh-sg-change-rule"
  description    = "Detect EC2 AuthorizeSecurityGroupIngress via CloudTrail"
  event_bus_name = "default"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["AuthorizeSecurityGroupIngress"]
    }
  })

  tags = { Name = "skills-ceh-sg-change-rule" }
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule           = aws_cloudwatch_event_rule.sg_change.name
  event_bus_name = "default"
  target_id      = "skills-ceh-remediate-fn"
  arn            = var.lambda_arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.sg_change.arn
}
