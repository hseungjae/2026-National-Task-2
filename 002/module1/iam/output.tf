output "lambda_role_arn" {
  value = aws_iam_role.lambda_student.arn
}

output "stepfunction_role_arn" {
  value = aws_iam_role.stepfunction_student.arn
}

output "lambda_trigger_role_arn" {
  value = aws_iam_role.lambda_trigger.arn
}
