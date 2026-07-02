resource "aws_cloudfront_key_value_store" "kvs" {
  name = "${var.prefix}-cdn-ab-config"
}

resource "aws_cloudfrontkeyvaluestore_key" "weight" {
  key_value_store_arn = aws_cloudfront_key_value_store.kvs.arn
  key                 = "weight"
  value               = "0.3"
}

resource "aws_cloudfrontkeyvaluestore_key" "version_a" {
  key_value_store_arn = aws_cloudfront_key_value_store.kvs.arn
  key                 = "version_a"
  value               = "/version-a/index.html"
}

resource "aws_cloudfrontkeyvaluestore_key" "version_b" {
  key_value_store_arn = aws_cloudfront_key_value_store.kvs.arn
  key                 = "version_b"
  value               = "/version-b/index.html"
}
