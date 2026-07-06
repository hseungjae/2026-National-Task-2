variable "prefix" {}
variable "private_subnet" {}
variable "al2023_ami" {}
variable "keycloak_sg" {}
variable "keycloak_admin_password" {
  sensitive = true
}