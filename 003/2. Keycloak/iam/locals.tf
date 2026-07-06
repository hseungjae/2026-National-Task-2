locals {
  saml_trust_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowSAMLFederation"
      Effect    = "Allow"
      Principal = { Federated = aws_iam_saml_provider.keycloak.arn }
      Action    = "sts:AssumeRoleWithSAML"
      Condition = {
        StringEquals = {
          "SAML:aud" = "https://signin.aws.amazon.com/saml"
        }
      }
    }]
  })
}
