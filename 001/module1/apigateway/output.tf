output "api_id" {
  value = aws_api_gateway_rest_api.rest_api.id
}

output "api_endpoint" {
  value = "https://${aws_api_gateway_rest_api.rest_api.id}.execute-api.${var.region}.amazonaws.com/${var.stage_name}/items"
}
