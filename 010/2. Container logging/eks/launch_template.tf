resource "aws_launch_template" "node_lt" {
  name = "${var.prefix}-ng-lt"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.prefix}-logging-worker-node"
    }
  }
}
