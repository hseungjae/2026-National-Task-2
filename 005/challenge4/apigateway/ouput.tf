output "api_endpoint" {
  value = "${aws_api_gateway_stage.prod.invoke_url}"
}

output "api_key_id" {
  value = aws_api_gateway_api_key.this.id
}

output "api_key_value" {
  value     = aws_api_gateway_api_key.this.value
  sensitive = true
}
