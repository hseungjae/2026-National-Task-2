output "sg_ssh_rule_name" {
  value = aws_config_config_rule.sg_ssh.name
}

output "required_tags_rule_name" {
  value = aws_config_config_rule.required_tags.name
}
