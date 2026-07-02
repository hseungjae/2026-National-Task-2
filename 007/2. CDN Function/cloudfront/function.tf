resource "aws_cloudfront_function" "viewer_request" {
  name    = "${var.prefix}-cdn-ab-req-fn"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/functions/viewer_request.js")

  key_value_store_associations = [aws_cloudfront_key_value_store.kvs.arn]
}

resource "aws_cloudfront_function" "viewer_response" {
  name    = "${var.prefix}-cdn-ab-res-fn"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/functions/viewer_response.js")
}
