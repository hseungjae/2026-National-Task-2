output "role_arn" {
  value = aws_iam_role.api_handler_role.arn
}

output "policy_id" {
  value = aws_iam_policy.api_handler_policy.id
}
