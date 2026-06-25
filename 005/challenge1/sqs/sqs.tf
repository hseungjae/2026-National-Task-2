resource "aws_sqs_queue" "this" {
  name = "wsc-scaling-sqs"

  tags = {
    Name = "wsc-scaling-sqs"
  }
}
