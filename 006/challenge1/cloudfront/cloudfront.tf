locals {
  lambda_origin_id = "gj2026-cdn-rotate-origin"
  lambda_url_host  = replace(replace(var.lambda_url, "https://", ""), "/", "")
}

resource "aws_cloudfront_cache_policy" "images" {
  name        = "gj2026-cdn-images-policy"
  comment     = "Cache policy for CDN images with rotate support"
  default_ttl = 86400
  max_ttl     = 86400
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "whitelist"
      query_strings {
        items = ["image", "rotate"]
      }
    }
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true
  }
}

resource "aws_cloudfront_origin_request_policy" "images" {
  name    = "gj2026-cdn-origin-request-policy"
  comment = "Forward query strings to origin Lambda"

  cookies_config {
    cookie_behavior = "none"
  }
  headers_config {
    header_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "whitelist"
    query_strings {
      items = ["image", "rotate"]
    }
  }
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "gj2026-cdn distribution"
  price_class     = "PriceClass_All"

  origin {
    domain_name = local.lambda_url_host
    origin_id   = local.lambda_origin_id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.lambda_origin_id
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id        = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"
  }

  ordered_cache_behavior {
    path_pattern           = "/images"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = local.lambda_origin_id
    viewer_protocol_policy = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.images.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.images.id

    lambda_function_association {
      event_type   = "viewer-request"
      lambda_arn   = var.request_lambda_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = var.response_lambda_arn
      include_body = false
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = { Name = "gj2026-cdn" }

  lifecycle {
    ignore_changes = [ordered_cache_behavior]
  }
}
