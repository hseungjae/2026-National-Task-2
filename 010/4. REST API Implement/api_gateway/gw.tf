resource "aws_api_gateway_rest_api" "api" {
  name = "${var.prefix}-worldschool-api"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_method" "get_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  http_method             = aws_api_gateway_method.get_root.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method" "post_root" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_rest_api.api.root_resource_id
  http_method             = aws_api_gateway_method.post_root.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

# GET/POST 외 메서드(DELETE 등)로 접근 시 API Gateway 기본 응답(403
# MissingAuthenticationTokenException)을 스펙이 요구하는 405로 덮어씁니다.
resource "aws_api_gateway_gateway_response" "method_not_allowed" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  response_type = "MISSING_AUTHENTICATION_TOKEN"
  status_code   = "405"

  response_templates = {
    "application/json" = "잘못된 요청입니다."
  }
}

resource "aws_api_gateway_deployment" "dep" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  # GET/POST 메서드나 통합이 바뀌면 새 배포를 강제로 생성해서
  # 스테이지가 최신 상태를 반영하도록 합니다.
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.get_root.id,
      aws_api_gateway_integration.get_lambda.id,
      aws_api_gateway_method.post_root.id,
      aws_api_gateway_integration.post_lambda.id,
      aws_api_gateway_gateway_response.method_not_allowed.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_integration.get_lambda,
    aws_api_gateway_integration.post_lambda,
    aws_api_gateway_gateway_response.method_not_allowed,
  ]
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.dep.id
  stage_name    = "${var.prefix}-worldschool-api-stage"
}