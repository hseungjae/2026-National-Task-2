resource "keycloak_group" "infra_team" {
  realm_id = var.realm_id
  name     = "infra-team"
}

resource "keycloak_user" "infra" {
  realm_id       = var.realm_id
  username       = "infra-user"
  enabled        = true
  email          = "infra-user@wsc.local"
  email_verified = true
  first_name     = "infra"
  last_name      = "user"

  attributes = {
    Role = "${var.infra_role_arn},${var.saml_provider_arn}"
  }

  initial_password {
    value     = var.infra_user_password
    temporary = false
  }
}

resource "keycloak_user_groups" "infra" {
  realm_id  = var.realm_id
  user_id   = keycloak_user.infra.id
  group_ids = [keycloak_group.infra_team.id]
}
