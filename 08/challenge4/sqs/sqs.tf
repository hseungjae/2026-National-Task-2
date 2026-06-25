resource "aws_sqs_queue" "this" {
  name                       = "skills-sqs-queue"
  visibility_timeout_seconds = 30
  tags                       = { Name = "skills-sqs-queue" }
}
