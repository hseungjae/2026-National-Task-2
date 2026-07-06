resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.prefix}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  comment         = "${var.prefix}-cdn"
  enabled         = true

  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods          = ["GET", "HEAD"]
    target_origin_id        = "s3-origin"
    viewer_protocol_policy   = "redirect-to-https"

    cache_policy_id          = aws_cloudfront_cache_policy.cache.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.origin.id

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = var.lambda_arn
      include_body = false
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.device_detect.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.response_header.arn
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

  tags = {
    Name = "${var.prefix}-cdn"
  }
}

resource "aws_s3_bucket_policy" "cdn_access" {
  bucket = var.bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${var.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.cdn.arn
          }
        }
      }
    ]
  })
}
