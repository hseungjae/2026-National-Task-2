resource "aws_cloudtrail" "event_trail" {
  name                          = "wsc2026-event-trail"
  s3_bucket_name                = var.s3_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = { Name = "wsc2026-event-trail" }
}
