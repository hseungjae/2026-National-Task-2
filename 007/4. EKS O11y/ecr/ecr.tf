resource "aws_ecr_repository" "app" {
  name         = "${var.prefix}-app"
  force_delete = true
}
