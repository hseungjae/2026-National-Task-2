resource "aws_sqs_queue" "sqs" {
  name                       = "${var.prefix}-order-queue"

  tags = {
    Name = "${var.prefix}-order-queue"
  }
}