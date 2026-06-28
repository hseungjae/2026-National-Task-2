resource "aws_sqs_queue" "sqs" {
  name                       = "wsi-task-queue"
  visibility_timeout_seconds = 70

  tags = {
    Name = "wsi-task-queue"
  }
}
