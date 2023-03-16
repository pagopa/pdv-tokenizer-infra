resource "aws_api_gateway_documentation_version" "main" {
  # assign the deployment creation date as a version.
  version     = formatdate("YYYYMMDDHHmmss", aws_api_gateway_deployment.tokenizer.created_date)
  rest_api_id = aws_api_gateway_rest_api.tokenizer.id
  description = format("Documentation api %s", aws_api_gateway_rest_api.tokenizer.id)

  lifecycle {
    create_before_destroy = true
  }
}

# export api 
## open api

data "aws_api_gateway_export" "tokenizer" {
  rest_api_id = aws_api_gateway_stage.tokenizer.rest_api_id
  stage_name  = aws_api_gateway_stage.tokenizer.stage_name
  export_type = "oas30"
}

resource "aws_s3_object" "openapi_tokenizer" {
  key              = "openapi.json"
  bucket           = aws_s3_bucket.openapidocs.bucket
  content          = data.aws_api_gateway_export.tokenizer.body
  content_encoding = "utf-8"
  content_type     = "application/json"
}

resource "aws_api_gateway_rest_api" "openapi_tokenizer" {
  name        = format("%s-openapi", local.project)
  description = "Openapi tokenizer documentation."
}

resource "aws_api_gateway_resource" "folder" {
  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id
  parent_id   = aws_api_gateway_rest_api.openapi_tokenizer.root_resource_id
  path_part   = "{folder}"
}

resource "aws_api_gateway_resource" "item" {
  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id
  parent_id   = aws_api_gateway_resource.folder.id
  path_part   = "{item}"
}


resource "aws_api_gateway_method" "get_item" {
  rest_api_id   = aws_api_gateway_rest_api.openapi_tokenizer.id
  resource_id   = aws_api_gateway_resource.item.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.path.folder" = true
    "method.request.path.item"   = true
  }
}

resource "aws_api_gateway_integration" "openapi_tokenizer_integration" {
  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id
  resource_id = aws_api_gateway_resource.item.id

  http_method = aws_api_gateway_method.get_item.http_method

  integration_http_method = "GET"

  type = "AWS"

  uri         = format("arn:aws:apigateway:%s:s3:path/{bucket}/{object}", var.aws_region)
  credentials = aws_iam_role.s3_api_gateyway_role.arn

  request_parameters = {
    "integration.request.path.bucket" = "method.request.path.folder"
    "integration.request.path.object" = "method.request.path.item"
  }
}

resource "aws_api_gateway_method_response" "openapi_tokenizer_response_200" {
  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id
  resource_id = aws_api_gateway_resource.item.id
  http_method = aws_api_gateway_method.get_item.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration_response" "openapi_tokenizer_integration_200" {
  depends_on = [aws_api_gateway_integration.openapi_tokenizer_integration]

  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id
  resource_id = aws_api_gateway_resource.item.id
  http_method = aws_api_gateway_method.get_item.http_method
  status_code = aws_api_gateway_method_response.openapi_tokenizer_response_200.status_code
}


resource "aws_api_gateway_deployment" "openapi_tokenizer" {
  depends_on  = [aws_api_gateway_integration.openapi_tokenizer_integration]
  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id

}

resource "aws_api_gateway_stage" "openapi_tokenizer" {
  deployment_id      = aws_api_gateway_deployment.openapi_tokenizer.id
  rest_api_id        = aws_api_gateway_rest_api.openapi_tokenizer.id
  stage_name         = "v1"
  cache_cluster_size = 0.5
}

resource "aws_api_gateway_method_settings" "openapi_tokenizer" {
  rest_api_id = aws_api_gateway_rest_api.openapi_tokenizer.id
  stage_name  = aws_api_gateway_stage.openapi_tokenizer.stage_name
  method_path = "*/*"

  settings {
    caching_enabled        = true
    throttling_rate_limit  = 10
    throttling_burst_limit = 2
  }
}

## Mapping openapi with custom domain .
resource "aws_apigatewayv2_api_mapping" "openapi_tokrnizer" {
  count           = var.apigw_custom_domain_create ? 1 : 0
  api_id          = aws_api_gateway_rest_api.openapi_tokenizer.id
  stage           = aws_api_gateway_stage.openapi_tokenizer.stage_name
  domain_name     = aws_api_gateway_domain_name.main[0].domain_name
  api_mapping_key = "docs"
}