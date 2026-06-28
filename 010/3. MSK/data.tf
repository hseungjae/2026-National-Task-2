data "aws_ami" "al2023_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*kernel-6.1*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}