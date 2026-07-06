resource "keycloak_saml_client" "aws" {
  realm_id  = keycloak_realm.aws.id
  client_id = "urn:amazon:webservices"
  name      = "AWS Console"
  enabled   = true

  root_url                    = "https://signin.aws.amazon.com/saml"
  base_url                    = "https://signin.aws.amazon.com/saml"
  valid_redirect_uris         = ["https://signin.aws.amazon.com/saml"]
  master_saml_processing_url  = "https://signin.aws.amazon.com/saml"
  idp_initiated_sso_url_name  = "amazon-aws"

  name_id_format          = "persistent"
  force_name_id_format    = true
  force_post_binding      = true
  include_authn_statement = true

  sign_documents           = true
  sign_assertions          = true
  signature_algorithm      = "RSA_SHA256"
  canonicalization_method  = "EXCLUSIVE"
  client_signature_required = false
}

resource "keycloak_saml_user_property_protocol_mapper" "role_session_name" {
  realm_id      = keycloak_realm.aws.id
  client_id     = keycloak_saml_client.aws.id
  name          = "RoleSessionName"
  user_property = "username"

  saml_attribute_name        = "https://aws.amazon.com/SAML/Attributes/RoleSessionName"
  saml_attribute_name_format = "Basic"
}

resource "keycloak_generic_protocol_mapper" "session_duration" {
  realm_id        = keycloak_realm.aws.id
  client_id       = keycloak_saml_client.aws.id
  name            = "SessionDuration"
  protocol        = "saml"
  protocol_mapper = "saml-hardcode-attribute-mapper"

  config = {
    "attribute.name"       = "https://aws.amazon.com/SAML/Attributes/SessionDuration"
    "attribute.nameformat" = "Basic"
    "attribute.value"      = "28800"
  }
}

resource "keycloak_saml_user_attribute_protocol_mapper" "role" {
  realm_id       = keycloak_realm.aws.id
  client_id      = keycloak_saml_client.aws.id
  name           = "Role"
  user_attribute = "Role"

  saml_attribute_name        = "https://aws.amazon.com/SAML/Attributes/Role"
  saml_attribute_name_format = "Basic"
}