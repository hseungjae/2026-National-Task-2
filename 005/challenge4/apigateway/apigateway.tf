# REST API
resource "aws_api_gateway_rest_api" "this" {
  name = "wsc-rest-api"

  tags = { Name = "wsc-rest-api" }
}

# /v1 resource
resource "aws_api_gateway_resource" "v1" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "v1"
}

# /v1/healthcheck resource
resource "aws_api_gateway_resource" "healthcheck" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "healthcheck"
}

# /v1/user resource
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_resource.v1.id
  path_part   = "user"
}

# Request validator (validates query string params and headers)
resource "aws_api_gateway_request_validator" "params" {
  rest_api_id                 = aws_api_gateway_rest_api.this.id
  name                        = "validate-params"
  validate_request_parameters = true
  validate_request_body       = false
}

resource "aws_api_gateway_request_validator" "body" {
  rest_api_id                 = aws_api_gateway_rest_api.this.id
  name                        = "validate-body"
  validate_request_parameters = false
  validate_request_body       = true
}

# Model for POST /v1/user request body
resource "aws_api_gateway_model" "user_request" {
  rest_api_id  = aws_api_gateway_rest_api.this.id
  name         = "UserRequest"
  content_type = "application/json"

  schema = jsonencode({
    "$schema" = "http://json-schema.org/draft-04/schema#"
    title     = "UserRequest"
    type      = "object"
    required  = ["name", "age", "country"]
    properties = {
      name    = { type = "string" }
      age     = { type = "integer" }
      country = { type = "string" }
    }
  })
}

# GET /v1/healthcheck - MOCK integration
resource "aws_api_gateway_method" "healthcheck_get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.healthcheck.id
  http_method   = "GET"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_integration" "healthcheck_get" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.healthcheck_get.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

resource "aws_api_gateway_method_response" "healthcheck_get_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.healthcheck_get.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "healthcheck_get" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.healthcheck_get.http_method
  status_code = aws_api_gateway_method_response.healthcheck_get_200.status_code

  response_templates = {
    "application/json" = jsonencode({ status = "ok" })
  }

  depends_on = [aws_api_gateway_integration.healthcheck_get]
}

# POST /v1/user - Lambda integration with body validation
resource "aws_api_gateway_method" "user_post" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.user.id
  http_method          = "POST"
  authorization        = "NONE"
  api_key_required     = true
  request_validator_id = aws_api_gateway_request_validator.body.id

  request_models = {
    "application/json" = aws_api_gateway_model.user_request.name
  }
}

resource "aws_api_gateway_integration" "user_post" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.user_post.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "user_post_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.user.id
  http_method = aws_api_gateway_method.user_post.http_method
  status_code = "200"
}

# GET /v1/user - Lambda integration with query param validation
resource "aws_api_gateway_method" "user_get" {
  rest_api_id          = aws_api_gateway_rest_api.this.id
  resource_id          = aws_api_gateway_resource.user.id
  http_method          = "GET"
  authorization        = "NONE"
  api_key_required     = true
  request_validator_id = aws_api_gateway_request_validator.params.id

  request_parameters = {
    "method.request.querystring.name" = true
    "method.request.querystring.age"  = true
  }
}

resource "aws_api_gateway_integration" "user_get" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.user.id
  http_method             = aws_api_gateway_method.user_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_method_response" "user_get_200" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.user.id
  http_method = aws_api_gateway_method.user_get.http_method
  status_code = "200"
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

# Deploy to prod stage
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  depends_on = [
    aws_api_gateway_integration.healthcheck_get,
    aws_api_gateway_integration.user_post,
    aws_api_gateway_integration.user_get,
    aws_api_gateway_integration_response.healthcheck_get,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  stage_name    = "prod"
}

# API Key
resource "aws_api_gateway_api_key" "this" {
  name    = "wsc-rest-api-key"
  enabled = true
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "this" {
  name = "wsc-rest-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.this.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  throttle_settings {
    rate_limit  = 3000
    burst_limit = 5000
  }

  quota_settings {
    limit  = 1000000
    period = "MONTH"
  }
}

resource "aws_api_gateway_usage_plan_key" "this" {
  key_id        = aws_api_gateway_api_key.this.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.this.id
}
