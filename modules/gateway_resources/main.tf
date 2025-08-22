###########################################
# API Gateway + VPC Link module
###########################################

# REST API
resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project}-${var.env}-api"
  description = "Public API for ${var.project} via VPC Link -> ECS Fargate"
}

# / resource
resource "aws_api_gateway_resource" "app_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = ""
}

resource "aws_api_gateway_method" "get_app" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.app_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# VPC Link
resource "aws_api_gateway_vpc_link" "vpclink" {
  name        = "${var.project}-${var.env}-vpclink"
  target_arns = [var.nlb_arn]
}

# HTTP Integration using VPC Link
resource "aws_api_gateway_integration" "get_app_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.app_resource.id
  http_method             = aws_api_gateway_method.get_app.http_method
  type                    = "HTTP"
  integration_http_method = "GET"
  uri                     = "http://${var.nlb_dns}:8080/registration"
  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.vpclink.id
  passthrough_behavior    = "WHEN_NO_MATCH"
}


# Method Response
resource "aws_api_gateway_method_response" "get_app_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.app_resource.id
  http_method = aws_api_gateway_method.get_app.http_method
  status_code = "200"
}

# Integration Response
resource "aws_api_gateway_integration_response" "get_app_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.app_resource.id
  http_method = aws_api_gateway_method.get_app.http_method
  status_code = aws_api_gateway_method_response.get_app_200.status_code

  response_templates = {
    "application/json" = ""
  }
}

# Deploy API
resource "aws_api_gateway_deployment" "api_deploy" {
  depends_on = [
    aws_api_gateway_integration.get_app_integration,
    aws_api_gateway_integration_response.get_app_200
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

# Stage
resource "aws_api_gateway_stage" "stage" {
  stage_name    = var.env
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.api_deploy.id
}
