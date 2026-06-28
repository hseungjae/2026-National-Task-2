output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.keycloak.arn
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.keycloak.url
}

output "dev_team_role_arn" {
  value = aws_iam_role.dev_team.arn
}

output "dev_team_role_name" {
  value = aws_iam_role.dev_team.name
}

output "sec_team_role_arn" {
  value = aws_iam_role.sec_team.arn
}

output "sec_team_role_name" {
  value = aws_iam_role.sec_team.name
}
