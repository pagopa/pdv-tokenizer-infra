locals {
  task_tokenizer_name    = format("%s-task-tokenizer", local.project)
  service_tokenizer_name = format("%s-service-tokenizer", local.project)

  api_key_list = { for k in var.tokenizer_plans : k.key_name => k }

  additional_keys = flatten([for k in var.tokenizer_plans :
    [for a in k.additional_keys :
      {
        "key" : a
        "plan" : k.key_name
    }]
  ])

  tokenizer_api_name   = format("%s-tokenizer-api", local.project)
  tokenizer_stage_name = "v1"
  list_tokenizer_key_to_name = concat(
    [for n in var.tokenizer_plans : "'${aws_api_gateway_api_key.main[n.key_name].id}':'${n.key_name}'"],
    [for n in local.additional_keys : "'${aws_api_gateway_api_key.additional[n.key].id}':'${n.plan}'"]
  )

  tokenizer_log_group_name = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.tokenizer.id}/${local.tokenizer_stage_name}"

  tokenizer_api_plan_ids = merge(
    { for k in keys(local.api_key_list) : k => aws_api_gateway_usage_plan.tokenizer[k].id },
    { for k in local.additional_keys : k.key => aws_api_gateway_usage_plan.tokenizer[k.plan].id },
  )
}