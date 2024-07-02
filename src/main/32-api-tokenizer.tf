resource "aws_api_gateway_rest_api" "tokenizer" {
  name           = local.tokenizer_api_name
  api_key_source = "HEADER"

  body = templatefile("./api/ms_tokenizer/api-docs.json.tftpl",
    {
      uri           = format("http://%s", module.nlb.lb_dns_name),
      connection_id = aws_api_gateway_vpc_link.apigw.id
      request_template = chomp(templatefile("./api/request_template.tftpl",
        {
          list_key_to_name = join(",", local.list_tokenizer_key_to_name)
      }))
      responses            = file("./api/ms_tokenizer/status_code_mapping.tpl.json")
      responses_only_token = file("./api/ms_tokenizer/status_code_mapping_only_token.tpl.json")
    }
  )

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = { Name = local.tokenizer_api_name }
}

resource "aws_api_gateway_deployment" "tokenizer" {
  rest_api_id = aws_api_gateway_rest_api.tokenizer.id
  # stage_name  = local.tokenizer_stage_name

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.tokenizer.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "tokenizer" {
  name              = local.tokenizer_log_group_name
  retention_in_days = var.apigw_execution_logs_retention

  tags = { Name = local.tokenizer_api_name }
}
resource "aws_api_gateway_stage" "tokenizer" {
  deployment_id         = aws_api_gateway_deployment.tokenizer.id
  rest_api_id           = aws_api_gateway_rest_api.tokenizer.id
  stage_name            = local.tokenizer_stage_name
  cache_cluster_size    = 0.5 #why is this needed ?
  documentation_version = aws_api_gateway_documentation_version.main.version
  xray_tracing_enabled  = true

  dynamic "access_log_settings" {
    for_each = var.apigw_access_logs_enable ? ["dymmy"] : []
    content {
      destination_arn = aws_cloudwatch_log_group.tokenizer.arn
      #todo: find a better way to represent this log format.
      format = "{ \"requestId\":\"$context.requestId\", \"extendedRequestId\":\"$context.extendedRequestId\", \"ip\": \"$context.identity.sourceIp\", \"caller\":\"$context.identity.caller\", \"user\":\"$context.identity.user\", \"requestTime\":\"$context.requestTime\", \"httpMethod\":\"$context.httpMethod\", \"resourcePath\":\"$context.resourcePath\", \"status\":\"$context.status\", \"protocol\":\"$context.protocol\", \"responseLength\":\"$context.responseLength\"}"
    }
  }
}

resource "aws_api_gateway_method_settings" "tokenizer" {
  rest_api_id = aws_api_gateway_rest_api.tokenizer.id
  stage_name  = local.tokenizer_stage_name
  method_path = "*/*"

  settings {
    # Enable CloudWatch logging and metrics
    metrics_enabled    = true
    data_trace_enabled = var.apigw_data_trace_enabled
    logging_level      = "ERROR"
    #todo.
    # Limit the rate of calls to prevent abuse and unwanted charges
    #throttling_rate_limit  = 100
    #throttling_burst_limit = 50
  }
}

resource "aws_api_gateway_usage_plan" "tokenizer" {
  for_each    = local.api_key_list
  name        = format("%s-api-plan-%s", local.project, lower(each.key))
  description = "Usage plan for tokenizer apis"

  api_stages {
    api_id = aws_api_gateway_rest_api.tokenizer.id
    stage  = aws_api_gateway_stage.tokenizer.stage_name

    dynamic "throttle" {
      for_each = each.value.method_throttle
      content {
        path        = throttle.value.path
        burst_limit = throttle.value.burst_limit
        rate_limit  = throttle.value.rate_limit
      }
    }
  }

  /*
  quota_settings {
    limit  = 20
    offset = 2
    period = "WEEK"
  }
  */

  #TODO: tune this settings
  throttle_settings {
    burst_limit = each.value.burst_limit
    rate_limit  = each.value.rate_limit
  }
}

resource "aws_api_gateway_usage_plan_key" "tokenizer" {
  for_each      = local.api_key_list
  key_id        = aws_api_gateway_api_key.main[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.tokenizer[each.key].id
}

resource "aws_api_gateway_usage_plan_key" "tokenizer_additional" {
  for_each      = { for k in local.additional_keys : k.key => k }
  key_id        = aws_api_gateway_api_key.additional[each.key].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.tokenizer[each.value.plan].id

  depends_on = [
    aws_api_gateway_api_key.additional
  ]
}


## Mapping api tokenizer with apigw custom domain.
resource "aws_apigatewayv2_api_mapping" "tokenizer" {
  count           = var.apigw_custom_domain_create ? 1 : 0
  api_id          = aws_api_gateway_rest_api.tokenizer.id
  stage           = aws_api_gateway_stage.tokenizer.stage_name
  domain_name     = aws_api_gateway_domain_name.main[0].domain_name
  api_mapping_key = format("tokenizer/%s", aws_api_gateway_stage.tokenizer.stage_name)
}

## WAF association
resource "aws_wafv2_web_acl_association" "tokenizer" {
  web_acl_arn  = aws_wafv2_web_acl.main.arn
  resource_arn = "arn:aws:apigateway:${var.aws_region}::/restapis/${aws_api_gateway_rest_api.tokenizer.id}/stages/${aws_api_gateway_stage.tokenizer.stage_name}"
}

/*
//The API Gateway endpoint
output "api_gateway_endpoint" {
  value = format("https://", aws_api_gateway_domain_name.main.domain_name)
}
*/
output "tokenizerinvoke_url" {
  value = aws_api_gateway_deployment.tokenizer.invoke_url
}

## Alarms
### 4xx
module "api_tokenizer_4xx_error_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarms-by-multiple-dimensions"
  version = "3.0"

  actions_enabled     = var.env_short == "p" ? true : false
  alarm_name          = "high-4xx-rate-"
  alarm_description   = "Api tokenizer error rate has exceeded the threshold."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = 200
  period              = 300
  unit                = "Count"
  datapoints_to_alarm = 1

  namespace   = "AWS/ApiGateway"
  metric_name = "4XXError"
  statistic   = "Sum"

  dimensions = {
    "${local.tokenizer_api_name}" = {
      ApiName = local.tokenizer_api_name
      Stage   = local.tokenizer_stage_name
    },
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
}

### 5xx
module "api_tokenizer_5xx_error_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarms-by-multiple-dimensions"
  version = "3.0"

  alarm_name          = "high-5xx-rate-"
  alarm_description   = "${local.runbook_title} ${local.runbook_url} Api tokenizer error rate has exceeded 0% "
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 2
  period              = 300
  unit                = "Count"
  datapoints_to_alarm = 1

  namespace   = "AWS/ApiGateway"
  metric_name = "5XXError"
  statistic   = "Sum"

  dimensions = {
    "${local.tokenizer_api_name}" = {
      ApiName = local.tokenizer_api_name
      Stage   = local.tokenizer_stage_name
    },
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
}

### throttling (exceeded throttle limit)
module "log_filter_throttle_limit_tokenizer" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/log-metric-filter"
  version = "3.0"

  name = format("%s-metric-throttle-rate-limit", local.tokenizer_api_name)

  log_group_name = local.tokenizer_log_group_name

  pattern = "exceeded throttle limit"

  metric_transformation_namespace = "ErrorCount"
  metric_transformation_name      = format("%s-namespace", local.tokenizer_api_name)

  depends_on = [
    aws_cloudwatch_log_group.tokenizer
  ]

}

module "api_tokenizer_throttle_limit_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarm"
  version = "3.0"

  actions_enabled     = var.env_short == "p" ? true : false
  alarm_name          = format("high-rate-limit-throttle-%s", local.tokenizer_api_name)
  alarm_description   = "Throttle rate limit too high."
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = 1
  evaluation_periods  = 2
  threshold           = 20
  period              = 300
  #unit                = "Count"

  namespace   = "ErrorCount"
  metric_name = format("%s-namespace", local.tokenizer_api_name)
  statistic   = "Sum"

  alarm_actions = [aws_sns_topic.alarms.arn]

  depends_on = [
    module.log_filter_throttle_limit_tokenizer
  ]
}

locals {
  latency_threshold = 300 # ms
}

module "api_tokenizer_low_latency_alarm" {
  source  = "terraform-aws-modules/cloudwatch/aws//modules/metric-alarms-by-multiple-dimensions"
  version = "3.0"

  actions_enabled     = var.env_short == "p" ? true : false
  alarm_name          = "low-latency-"
  alarm_description   = format("The Api responds in more than %s ms.", local.latency_threshold)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  threshold           = local.latency_threshold
  period              = 300
  # unit                = "Count"
  datapoints_to_alarm = 1

  namespace   = "AWS/ApiGateway"
  metric_name = "Latency"
  statistic   = "Average"

  dimensions = {
    "${local.tokenizer_api_name}" = {
      ApiName = local.tokenizer_api_name
      Stage   = local.tokenizer_stage_name
    },
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
}
