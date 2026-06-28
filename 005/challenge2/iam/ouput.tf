output "bastion_instance_profile_name" {
  value = aws_iam_instance_profile.bastion.name
}

output "app_instance_profile_name" {
  value = aws_iam_instance_profile.app.name
}
