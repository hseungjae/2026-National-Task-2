output "ec2_role_name" {
  value = aws_iam_role.ec2.name
}

output "ec2_profile_name" {
  value = aws_iam_instance_profile.ec2.name
}

output "recovery_lambda_role_arn" {
  value = aws_iam_role.recovery_lambda.arn
}

output "updater_lambda_role_arn" {
  value = aws_iam_role.updater_lambda.arn
}
