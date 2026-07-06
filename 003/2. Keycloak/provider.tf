# provider.tf
terraform {
  required_providers {
    keycloak = {
      source = "mrparkers/keycloak"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

provider "aws" {
  region  = var.region
  profile = var.awscli_profile
}

provider "keycloak" {
  client_id      = "admin-cli"
  username       = "admin"
  password       = var.keycloak_admin_password
  url            = "http://${data.aws_lb.keycloak.dns_name}"
  initial_login  = false
  base_path      = ""
  client_timeout = 60
}
