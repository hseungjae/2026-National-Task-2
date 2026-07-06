resource "aws_iam_saml_provider" "keycloak" {
  name                   = "${var.prefix}-keycloak-idp"
  saml_metadata_document = data.http.saml_metadata.response_body

  tags = {
    Name    = "${var.prefix}-keycloak-idp"
    Purpose = "SSO via Keycloak"
  }
}