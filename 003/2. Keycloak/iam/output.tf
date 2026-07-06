output "saml_provider_arn" {
  value = aws_iam_saml_provider.keycloak.arn
}

output "dev_role_arn" {
  value = aws_iam_role.dev.arn
}

output "infra_role_arn" {
  value = aws_iam_role.infra.arn
}

output "dev_policy_arn" {
  value = aws_iam_policy.dev.arn
}

output "infra_policy_arn" {
  value = aws_iam_policy.infra.arn
}
