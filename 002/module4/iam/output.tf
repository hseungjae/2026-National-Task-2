output "ec2_instance_profile_name" {
  value = aws_iam_instance_profile.msk_ec2.name
}

output "ec2_role_arn" {
  value = aws_iam_role.msk_ec2.arn
}

output "lambda_role_arn" {
  value = aws_iam_role.msk_lambda.arn
}
