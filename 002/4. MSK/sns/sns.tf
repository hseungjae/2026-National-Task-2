resource "aws_sns_topic" "sensor_alert" {
  name = "wsc2026-sensor-alert"
  tags = { Name = "wsc2026-sensor-alert" }
}
