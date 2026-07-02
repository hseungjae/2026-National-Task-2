resource "aws_sns_topic" "event_alert" {
  name = "wsc2026-event-alert"
  tags = { Name = "wsc2026-event-alert" }
}
