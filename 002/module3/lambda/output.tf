output "function_arns" {
  value = {
    sg_remediation       = aws_lambda_function.sg_remediation.arn
    role_remediation     = aws_lambda_function.role_remediation.arn
    ec2_terminate_alert  = aws_lambda_function.ec2_terminate_alert.arn
    ec2_type_remediation = aws_lambda_function.ec2_type_remediation.arn
    ec2_stop_remediation = aws_lambda_function.ec2_stop_remediation.arn
    tag_alert            = aws_lambda_function.tag_alert.arn
  }
}

output "function_names" {
  value = {
    sg_remediation       = aws_lambda_function.sg_remediation.function_name
    role_remediation     = aws_lambda_function.role_remediation.function_name
    ec2_terminate_alert  = aws_lambda_function.ec2_terminate_alert.function_name
    ec2_type_remediation = aws_lambda_function.ec2_type_remediation.function_name
    ec2_stop_remediation = aws_lambda_function.ec2_stop_remediation.function_name
    tag_alert            = aws_lambda_function.tag_alert.function_name
  }
}
