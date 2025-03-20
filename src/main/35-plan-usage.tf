
# Lambda module configuration
module "lambda_api_usage_metrics" {
  count   = contains(["prod", "uat", var.environment]) ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.8.0"

  function_name = "api-usage-metrics"
  description   = "Collects API Gateway usage metrics and publishes to CloudWatch"
  handler       = "index.lambda_handler"
  runtime       = "python3.9"


  publish                = false
  local_existing_package = "../lambda/hello-python/lambda.zip"

  # Environment variables if needed
  cloudwatch_logs_retention_in_days = 14
  environment_variables = {
    LOG_LEVEL                    = "INFO"
    APIGATEWAY_METRICS_NAMESPACE = "'ApiGateway/UsagePlans'"
  }

  timeout = 30

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
  schedule_expression = "cron(59 * * * ? *)"
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


# Role to deploy the lambda functions with github actions

locals {
  assume_role_policy_github = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : [
              "repo:pagopa/pdv-lambda-usage-plans:*"
            ]
          },
          "ForAllValues:StringEquals" = {
            "token.actions.githubusercontent.com:iss" : "https://token.actions.githubusercontent.com",
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "deploy_lambda" {
  name        = format("%s-deploy-lambda", var.app_name)
  description = "Policy to deploy Lambda functions"

  policy = jsonencode({

    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "github_lambda_deploy" {
  name               = format("%s-deploy-lambda", var.app_name)
  description        = "Role to deploy lambda functions with github actions."
  assume_role_policy = local.assume_role_policy_github
}