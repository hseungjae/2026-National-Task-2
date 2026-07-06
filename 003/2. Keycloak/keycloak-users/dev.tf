resource "keycloak_group" "dev_team" {
  realm_id = var.realm_id
  name     = "dev-team"
}

resource "keycloak_user" "dev" {
  realm_id       = var.realm_id
  username       = "dev-user"
  enabled        = true
  email          = "dev-user@wsc.local"
  email_verified = true
  first_name     = "dev"
  last_name      = "user"

  attributes = {
    Role = "${var.dev_role_arn},${var.saml_provider_arn}"
  }

  initial_password {
    value     = var.dev_user_password
    temporary = false
  }
}

resource "keycloak_user_groups" "dev" {
  realm_id  = var.realm_id
  user_id   = keycloak_user.dev.id
  group_ids = [keycloak_group.dev_team.id]
}
