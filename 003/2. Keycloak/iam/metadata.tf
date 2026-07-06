data "http" "saml_metadata" {
  url = "${var.keycloak_url}/realms/${var.realm_name}/protocol/saml/descriptor"

  request_headers = {
    Accept = "application/xml"
  }
}