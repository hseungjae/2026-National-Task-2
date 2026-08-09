resource "aws_kinesis_stream" "order_stream" {
  name             = "wsc2026-order-stream"
  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = { Name = "wsc2026-order-stream" }
}
