variable "aws_region" {
  type        = string
  description = "AWS region to create resources. Default Milan"
  default     = "eu-south-1"
}

variable "app_name" {
  type        = string
  default     = "tokenizer"
  description = "App name. Tokenizer"

}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment"
}

variable "env_short" {
  type        = string
  default     = "d"
  description = "Evnironment short."
}

variable "vpc_cidr" {
  type        = string
  default     = "10.1.0.0/16"
  description = "VPC cidr."
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
  default     = ["eu-south-1a", "eu-south-1b", "eu-south-1c"]
}

variable "vpc_private_subnets_cidr" {
  type        = list(string)
  description = "Private subnets list of cidr."
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "vpc_public_subnets_cidr" {
  type        = list(string)
  description = "Private subnets list of cidr."
  default     = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "vpc_internal_subnets_cidr" {
  type        = list(string)
  description = "Internal subnets list of cidr. Mainly for private endpoints"
  default     = ["10.1.201.0/24", "10.1.202.0/24", "10.1.203.0/24"]
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Enable/Create nat gateway"
  default     = false
}

### VPC Peering
variable "vpc_peering" {
  type = object({
    owner_connection_id = string
    owner_cidr_block    = string
  })
  default     = null
  description = "Vpc peering configuration"
}

## Public Dns zones
variable "public_dns_zones" {
  type        = map(any)
  description = "Route53 Hosted Zone"
}

variable "dns_record_ttl" {
  type        = number
  description = "Dns record ttl (in sec)"
  default     = 86400 # 24 hours
}

## Api Gateway
variable "apigw_custom_domain_create" {
  type        = bool
  description = "Create apigw Custom Domain with its tls certificate"
  default     = false
}

variable "apigw_access_logs_enable" {
  type        = bool
  description = "Enable api gateway access logs"
  default     = false

}

variable "apigw_data_trace_enabled" {
  type        = bool
  description = "Specifies whether data trace logging is enabled. It effects the log entries pushed to Amazon CloudWatch Logs."
  default     = false
}

variable "apigw_execution_logs_retention" {
  type        = number
  default     = 7
  description = "Api gateway exection logs retention (days)"
}

## Web acl config
variable "web_acl_visibility_config" {
  type = object({
    cloudwatch_metrics_enabled = bool
    sampled_requests_enabled   = bool
  })
  default = {
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
  }
  description = "Cloudwatch metric eneble for web acl rules."
}

## ECR
variable "ecr_keep_nr_images" {
  type        = number
  description = "Number of images to keep."
  default     = 10
}

## ECS
variable "ecs_logs_retention_days" {
  type        = number
  description = "Specifies the number of days you want to retain log events in the specified log group."
  default     = 7
}

variable "ecs_enable_execute_command" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service."
  default     = false
}

variable "container_port_tokenizer" {
  type        = number
  description = "Container port tokenizer"
  default     = 8080
}

variable "tokenizer_image_version" {
  type        = string
  description = "Image version in task definition"
  default     = "latest"
}

variable "task_cpu" {
  type        = number
  description = "Container cpu quota."
  default     = 256
}

variable "task_memory" {
  type        = number
  description = "Container memory quota."
  default     = 512
}

variable "x_ray_daemon_container_cpu" {
  type        = number
  description = "Container cpu quota."
  default     = 32
}

variable "x_ray_daemon_container_memory" {
  type        = number
  description = "Container memory quota."
  default     = 256
}

variable "replica_count" {
  type        = number
  description = "Number of task replica"
  default     = 1
}

variable "ecs_autoscaling" {
  type = object({
    max_capacity       = number
    min_capacity       = number
    scale_in_cooldown  = number
    scale_out_cooldown = number
  })
  default = {
    max_capacity       = 3
    min_capacity       = 1
    scale_in_cooldown  = 180
    scale_out_cooldown = 40
  }

  description = "ECS Service autoscaling."
}

variable "ecs_as_threshold" {
  type = object({
    cpu_min = number
    cpu_max = number
    mem_min = number
    mem_max = number
  })
  default = {
    cpu_max = 80
    cpu_min = 20
    mem_max = 80
    mem_min = 60
  }
  description = "ECS Tasks autoscaling settings."
}

variable "ms_tokenizer_log_level" {
  type        = string
  default     = "DEBUG"
  description = "Log level micro service tokenizer"
}

variable "ms_tokenizer_rest_client_log_level" {
  type        = string
  default     = "FULL"
  description = "Rest client log level micro service tokenizer"
}

variable "ms_tokenizer_enable_confidential_filter" {
  type        = bool
  default     = false
  description = "Enable a filter to avoid logging confidential data"
}

variable "ms_tokenizer_enable_single_line_stack_trace_logging" {
  type        = bool
  default     = false
  description = "Enable logging stack trace in a single line"
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable container insight in ECS cluster"
  default     = false
}

# x-ray

variable "publish_x-ray_image" {
  type        = bool
  description = "Run docker command to push x-ray image"
  default     = false
}

variable "x_ray_daemon_image_version" {
  type        = string
  description = "Image version in task definition"
  default     = "latest"
}

variable "x_ray_daemon_image_uri" {
  type        = string
  description = "X-Ray daemon image URI"
  default     = "public.ecr.aws/xray/aws-xray-daemon"
}

variable "x_ray_daemon_image_sha" {
  type        = string
  description = "X-Ray daemon image sha"
  default     = "sha256:9f3e1362e1e986fc5e631389b499068e1db82762e6fdb572ed6b5e54b43f0744"
}


# Dynamodb 

variable "dynamodb_region_replication_enable" {
  type        = bool
  description = "Enable dyamodb deplicaton in a secondary region."
  default     = false
}

variable "dynamodb_point_in_time_recovery_enabled" {
  type        = bool
  description = "Enable dynamodb point in time recovery"
  default     = false
}

## Table Token
/*
variable "table_token_read_capacity" {
  type        = number
  description = "Table token read capacity."
}


variable "table_token_write_capacity" {
  type        = number
  description = "Table token read capacity."
}

variable "table_token_autoscaling_read" {
  type = object({
    scale_in_cooldown  = number
    scale_out_cooldown = number
    target_value       = number
    max_capacity       = number
  })
  description = "Read autoscaling settings table token."
}

variable "table_token_autoscaling_write" {
  type = object({
    scale_in_cooldown  = number
    scale_out_cooldown = number
    target_value       = number
    max_capacity       = number
  })
  description = "Write autoscaling settings table token."
}
*/
variable "table_token_stream_enabled" {
  type        = bool
  description = "Enable Streams"
  default     = false
}

# Event bridge

variable "create_event_bridge_pipe" {
  type        = bool
  description = "Create event bridge pipe."
  default     = false
}

variable "event_bridge_desired_state" {
  type        = string
  description = "Event bridge pipe desired state."
  default     = "RUNNING"
  validation {
    condition     = contains(["RUNNING", "STOPPED"], var.event_bridge_desired_state)
    error_message = "Desired state can be RUNNIG or STOPPED."
  }
}

variable "sqs_consumer_principals" {
  type        = list(string)
  description = "AWS iam that can read from the sqs queue."
  default     = []
}

// We assume every plan has its own api key
variable "tokenizer_plans" {
  type = list(object({
    key_name        = string
    burst_limit     = number
    rate_limit      = number
    additional_keys = list(string)
    method_throttle = list(object({
      path        = string
      burst_limit = number
      rate_limit  = number
    }))
  }))
  description = "Usage plan with its api key and rate limit."
}

/*
variable "table_token_autoscling_indexes" {
  type        = any
  description = "Autoscaling gsi configurations"
}
*/

variable "create_cloudhsm" {
  type        = bool
  description = "Create cloudhsm cluster to enctypt dynamodb tables"
  default     = false
}


## Alarms

variable "enable_opsgenie" {
  type        = bool
  default     = false
  description = "Send alarm via opsgenie."
}

variable "dynamodb_alarms" {
  type = list(
    object({
      actions_enabled     = bool
      alarm_name          = string
      alarm_description   = string
      comparison_operator = string
      evaluation_periods  = number
      datapoints_to_alarm = number
      threshold           = number
      period              = number
      unit                = string
      namespace           = string
      metric_name         = string
      statistic           = string
  }))

}

# Sentinel integration
variable "enable_sentinel_logs" {
  type        = bool
  default     = false
  description = "Create all resources required to sento logs to azure sentinel."
}

variable "sentinel_servcie_account_id" {
  type        = string
  description = "Microsoft Sentinel's service account ID for AWS."
  default     = "197857026523"
}

variable "sentinel_workspace_id" {
  type        = string
  description = "Sentinel workspece id"
  default     = null

}

variable "github_tokenizer_repo" {
  type        = string
  description = "Github repository allowed to run action for ECS deploy."
  default     = "pagopa/pdv-ms-tokenizer"
}


# lambda usage plan

variable "lambda_usage_plan" {
  type = object({
    schedule_expression = string
  })
  default = {
    schedule_expression = "cron(55 * * * ? *)"
  }
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "log_retention_days" {
  type    = number
  default = 7
}