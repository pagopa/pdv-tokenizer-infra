resource "aws_cloudwatch_dashboard" "main" {
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
    }
  )
}