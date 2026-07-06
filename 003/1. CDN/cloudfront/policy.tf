resource "aws_cloudfront_origin_request_policy" "origin" {
  name = "${var.prefix}-origin-policy"

  headers_config {
    header_behavior = "none"
  }

  query_strings_config {
    query_string_behavior = "all"
  }

  cookies_config {
    cookie_behavior = "none"
  }
}
