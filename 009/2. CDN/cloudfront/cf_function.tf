resource "aws_cloudfront_function" "security_header" {
  name    = "cdn-add-security-header"
  runtime = "cloudfront-js-2.0"
  publish = true

  code = <<EOF
function handler(event) {
    var response = event.response;

    response.headers['x-custom-header'] = {
        value: 'wsc2026'
    };

    return response;
}
EOF
}