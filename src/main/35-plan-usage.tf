
# Lambda module configuration
module "lambda_api_usage_metrics" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.8.0"

  function_name = "api-usage-metrics"
  description   = "Collects API Gateway usage metrics and publishes to CloudWatch"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  source_path = "../lambda/api_usage_plan" # Directory containing your Python code


  publish = true

  # Environment variables if needed
  cloudwatch_logs_retention_in_days = 14
  environment_variables = {
    LOG_LEVEL = "INFO"
  }

  timeout = 20

  # Attach policies
  attach_policy_statements = true
  policy_statements = {
    cloudwatch = {
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData"
      ]
      resources = ["*"]
    }
    apigateway = {
      effect = "Allow"
      actions = [
        "apigateway:GET",
        "apigateway:HEAD",
        "apigateway:OPTIONS"
      ]
      resources = [
        "arn:aws:apigateway:eu-south-1::/usageplans/*",
        "arn:aws:apigateway:eu-south-1::/usageplans",
      ]
    }
  }

}


resource "aws_cloudwatch_event_rule" "lambda_schedule" {
  name                = "api-usage-metrics-schedule"
  description         = "Schedule for API usage metrics collection"
  schedule_expression = "cron(55 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.lambda_schedule.name
  target_id = "api-usage-metrics"
  arn       = module.lambda_api_usage_metrics.lambda_function_arn
}

# Lambda permission to allow EventBridge to invoke the function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_usage_metrics.lambda_function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_schedule.arn
}


## Lambda for custom widgets ##

module "lambda_api_usage_widget" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.8.0"

  function_name = "api-usage-widget"
  description   = "Custom widget for API Gateway usage dashboard"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"

  source_path = "../lambda/widget_api_usage_plan"

  publish = true

  timeout = 20

  /*
  allowed_triggers = {
    CloudWatch = {
      principal  = "cloudwatch.amazonaws.com"
      source_arn = "*"
    }
  }
*/
  attach_policy_statements = true
  policy_statements = {
    apigateway = {
      effect = "Allow"
      actions = [
        "apigateway:GET"
      ]
      resources = [
        "arn:aws:apigateway:eu-south-1::/usageplans/*",
        "arn:aws:apigateway:eu-south-1::/usageplans",
      ]
    }
  }
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowCloudWatchCustomWidget"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_api_usage_widget.lambda_function_name
  principal     = "cloudwatch.amazonaws.com"
}