resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.prefix}-cdn-ab-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "ab" {
  comment             = "${var.prefix}-cdn-ab-distribution"
  enabled             = true

  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_id                = "${var.prefix}-s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id           = "${var.prefix}-s3"
    viewer_protocol_policy     = "redirect-to-https"
    cache_policy_id            = aws_cloudfront_cache_policy.ab_cache.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.ab_response_headers.id
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.viewer_request.arn
    }

    function_association {
      event_type   = "viewer-response"
      function_arn = aws_cloudfront_function.viewer_response.arn
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
    Name = "${var.prefix}-cdn-ab-distribution"
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = var.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${var.bucket_id}/*"
      Condition = {
        StringEquals = {
          "AWS:SourceArn" = aws_cloudfront_distribution.ab.arn
        }
      }
    }]
  })
}
