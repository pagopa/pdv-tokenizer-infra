resource "aws_cloudwatch_dashboard" "ms_tokenizer" {
  dashboard_name = "MS-Tokenizer"

  dashboard_body = templatefile("${path.module}/dashboards/main.tpl.json",
    {
      aws_region               = var.aws_region
      tokenizer_api_name       = aws_api_gateway_rest_api.tokenizer.name
      nlb_arn_suffix           = module.nlb.lb_arn_suffix
      nlb_target_arn_suffix    = module.nlb.target_group_arn_suffixes[0]
      ecs_tokenizer_service    = aws_ecs_service.tokenizer.name
      ecs_cluster_name         = aws_ecs_cluster.ecs_cluster.name
      waf_web_acl              = aws_wafv2_web_acl.main.name
      tokenizer_api_plan_ids   = local.tokenizer_api_plan_ids
      tokenizer_api_id         = aws_api_gateway_rest_api.tokenizer.id
      tokenizer_api_state_name = aws_api_gateway_stage.tokenizer.stage_name
      runbook_title            = local.runbook_title
      runbook_url              = local.runbook_url
    }
  )
}


resource "aws_cloudwatch_dashboard" "usage_plans" {
  count          = contains(["prod", "uat"], var.environment) ? 1 : 0
  dashboard_name = "Usage-Plans"

  dashboard_body = templatefile("${path.module}/dashboards/usage_plans.tpl.json",
    {
      aws_region             = var.aws_region
      usage_plans            = aws_api_gateway_usage_plan.tokenizer
      api_keys_main          = aws_api_gateway_api_key.main
      api_keys_additional    = aws_api_gateway_api_key.additional
      tokenizer_api_plan_ids = local.tokenizer_api_plan_ids
      additional_keys        = local.additional_keys
      plan_colors            = local.plan_colors
      additional_key_colors  = local.additional_key_colors
    }
  )
}