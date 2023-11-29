output "vpc_cidr" {
  value = module.vpc.vpc_cidr_block
}

## ecs
output "ecs_definition_task_arn" {
  value = data.aws_ecs_task_definition.tokenizer.arn
}

output "ecs_definition_task_revision" {
  value = data.aws_ecs_task_definition.tokenizer.revision
}

output "ecs_task_definition_tokenizer_arn" {
  value = data.aws_ecs_task_definition.tokenizer.arn
}

output "ecs_task_definition_tokenizer_revision" {
  value = data.aws_ecs_task_definition.tokenizer.revision
}

output "publsh_dokcer_image_x-ray" {
  value = <<EOF
	    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com
	    docker pull ${var.x_ray_daemon_image_uri}@${var.x_ray_daemon_image_sha}
      docker tag ${var.x_ray_daemon_image_uri}@${var.x_ray_daemon_image_sha} ${aws_ecr_repository.main[1].repository_url}:${var.x_ray_daemon_image_version}
	    docker push ${aws_ecr_repository.main[1].repository_url}:${var.x_ray_daemon_image_version}
	    EOF
}

## dynamodb

output "dynamodb_table_token_arn" {
  value = module.dynamodb_table_token.dynamodb_table_arn
}
output "dynamodb_table_token_id" {
  value = module.dynamodb_table_token.dynamodb_table_id
}

output "dynamodb_table_token_stream_arn" {
  value = var.table_token_stream_enabled ? module.dynamodb_table_token.dynamodb_table_stream_arn : null
}

# Dns
output "public_dns_zone_name" {
  value = module.dn_zone.route53_zone_name
}

output "public_dns_servers" {
  value = module.dn_zone.route53_zone_name_servers
}

# NLB
output "nlb_hostname" {
  value = module.nlb.lb_dns_name
}

# API Gateway

output "api_gateway_endpoint" {
  value = var.apigw_custom_domain_create ? format("https://%s", aws_api_gateway_domain_name.main[0].domain_name) : ""
}

output "openapi_endpoint" {
  value = var.apigw_custom_domain_create ? format("https://%s/docs/%s/%s",
    aws_api_gateway_domain_name.main[0].domain_name,
    aws_s3_bucket.openapidocs.id,
  aws_s3_object.openapi_tokenizer.key, ) : ""
}

output "tokenizer_api_keys" {
  value     = { for k in keys(local.api_key_list) : k => aws_api_gateway_usage_plan_key.tokenizer[k].value }
  sensitive = true
}

output "tokenizer_api_ids" {
  value = local.tokenizer_api_plan_ids
}


# cloud hsm
output "cloudhsm_cluster_id" {
  value = try(aws_cloudhsm_v2_cluster.main[0].id, null)
}

output "cloudhsm_cluster_certificates" {
  value     = try(aws_cloudhsm_v2_cluster.main[0].cluster_certificates, null)
  sensitive = true
}

output "cloudhsm_hsm_id" {
  value = try(aws_cloudhsm_v2_hsm.hsm1[0].hsm_id, null)
}

output "clouthsm_hsm_eni_ip" {
  value = try(data.aws_network_interface.hsm[0].private_ip, null)
}

# sentinel
output "sentinel_role_arn" {
  value = try(module.sentinel[0].sentinel_role_arn, null)
}

output "sentinel_queue_url" {
  value = try(module.sentinel[0].sentinel_queue_url, null)
}

# github action role.
output "github_ecs_deploy_role_arn" {
  value = aws_iam_role.githubecsdeploy.arn
}