resource "aws_sns_topic" "alert" {
  name = "skills-ceh-alert-topic"
  tags = { Name = "skills-ceh-alert-topic" }
}
