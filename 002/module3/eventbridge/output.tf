output "sg_change_rule_arn" {
  value = aws_cloudwatch_event_rule.sg_change.arn
}

output "role_change_rule_arn" {
  value = aws_cloudwatch_event_rule.role_change.arn
}
