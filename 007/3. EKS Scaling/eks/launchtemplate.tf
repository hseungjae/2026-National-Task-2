resource "aws_launch_template" "node" {
  name = "${var.prefix}-addon-lt"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-cluster-addon-ng-node"
    }
  }
}