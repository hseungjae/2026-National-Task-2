resource "aws_cloudfront_response_headers_policy" "ab_response_headers" {
  name = "${var.prefix}-cdn-ab-response-headers"

  security_headers_config {
    content_type_options {
      override = true
    }
  }
}

resource "aws_cloudfront_cache_policy" "ab_cache" {
  name        = "${var.prefix}-cdn-ab-cache-policy"
  min_ttl     = 0
  default_ttl = 300
  max_ttl     = 3600

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "whitelist"
      cookies {
        items = ["x-sp-ab"]
      }
    }

    headers_config {
      header_behavior = "none"
    }

    query_strings_config {
      query_string_behavior = "none"
    }
  }
}
