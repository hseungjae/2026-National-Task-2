resource "aws_cloudtrail" "this" {
  name                          = "skills-ceh-cloudtrail"
  s3_bucket_name                = var.s3_bucket_name
  include_global_service_events = false
  is_multi_region_trail         = false
  enable_logging                = true

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = true
  }
}
