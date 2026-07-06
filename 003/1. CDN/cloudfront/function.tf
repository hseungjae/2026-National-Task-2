resource "aws_cloudfront_function" "device_detect" {
  name    = "${var.prefix}-device-detect"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/function_code/device_detect.js")
}

resource "aws_cloudfront_function" "response_header" {
  name    = "${var.prefix}-response-header"
  runtime = "cloudfront-js-2.0"
  publish = true
  code    = file("${path.module}/function_code/response_header.js")
}
