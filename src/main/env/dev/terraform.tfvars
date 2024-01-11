env_short   = "d"
environment = "dev"

# Network
enable_nat_gateway = false

## Vpc peering

vpc_peering = {
  owner_connection_id = "pcx-04c79d8e79c830aff"
  owner_cidr_block    = "10.0.0.0/16"
}


# Ecs
ecs_enable_execute_command = true

replica_count                 = 1
ecs_logs_retention_days       = 90
tokenizer_image_version       = "42ca923ea7bf0ae8c01102c3d1323422955fb84f"
task_cpu                      = 256
task_memory                   = 512
x_ray_daemon_container_cpu    = 32
x_ray_daemon_container_memory = 256

ecs_autoscaling = {
  max_capacity       = 10
  min_capacity       = 1
  scale_in_cooldown  = 900 # 15 min  
  scale_out_cooldown = 60
}

enable_container_insights = true

# Public DNS Zone.

public_dns_zones = {
  "dev.tokenizer.pdv.pagopa.it" = {
    comment = "Personal data vault (Dev)"
  }
}


# App
ms_tokenizer_enable_single_line_stack_trace_logging = true


# Api Gateway

apigw_custom_domain_create = true
apigw_access_logs_enable   = false

tokenizer_plans = [
  {
    key_name        = "SANDBOX"
    burst_limit     = 20
    rate_limit      = 10
    additional_keys = []
    method_throttle = []
  },
  # Github Action Key for Integration Testing
  {
    key_name        = "GITHUB-KEY"
    burst_limit     = 20
    rate_limit      = 10
    additional_keys = []
    method_throttle = []
  },
]


# dynamodb
dynamodb_point_in_time_recovery_enabled = false


## table Token
/*
table_token_read_capacity  = 20
table_token_write_capacity = 100

table_token_stream_enabled = true

table_token_autoscaling_read = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 50 # target utilisation %
  max_capacity       = 100
}

table_token_autoscaling_write = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 50 # target utilisation %
  max_capacity       = 100
}



table_token_autoscling_indexes = {
  gsi_token = {
    read_max_capacity  = 100
    read_min_capacity  = 20
    write_max_capacity = 100
    write_min_capacity = 20
  }
}
*/

## Event bridge
create_event_bridge_pipe   = false
event_bridge_desired_state = "STOPPED"
sqs_consumer_principals    = []

## alarms
dynamodb_alarms = [{
  actions_enabled     = true
  alarm_name          = "dynamodb-account-provisioned-read-capacity"
  alarm_description   = "Account provisioned read capacity greater than 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  datapoints_to_alarm = null
  threshold           = 80

  period = 300
  unit   = "Percent"

  namespace   = "AWS/DynamoDB"
  metric_name = "AccountProvisionedReadCapacityUtilization"
  statistic   = "Maximum"

  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-account-provisioned-write-capacity"
    alarm_description   = "Account provisioned write capacity greater than 80%"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    datapoints_to_alarm = null
    threshold           = 80
    period              = 300
    unit                = "Percent"
    namespace           = "AWS/DynamoDB"
    metric_name         = "AccountProvisionedWriteCapacityUtilization"
    statistic           = "Maximum"
  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-max-provisioned-table-read-capacity-utilization"
    alarm_description   = "Account provisioned write capacity greater than 80%"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    datapoints_to_alarm = null
    threshold           = 80
    period              = 300
    unit                = "Percent"

    namespace   = "AWS/DynamoDB"
    metric_name = "MaxProvisionedTableReadCapacityUtilization"
    statistic   = "Maximum"
  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-max-provisioned-table-write-capacity-utilization"
    alarm_description   = "Account provisioned write capacity greater than 80%"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    datapoints_to_alarm = null
    threshold           = 80
    period              = 300
    unit                = "Percent"

    namespace   = "AWS/DynamoDB"
    metric_name = "MaxProvisionedTableWriteCapacityUtilization"
    statistic   = "Maximum"
  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-consumed-read-capacity-units"
    alarm_description   = "Consumed Read Capacity Units"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    datapoints_to_alarm = null
    threshold           = 10 #TODO this threashold should be equal to the Read Capacy Unit.
    period              = 300
    unit                = "Count"

    namespace   = "AWS/DynamoDB"
    metric_name = "ConsumedReadCapacityUnits"
    statistic   = "Maximum"
  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-consumed-write-capacity-units"
    alarm_description   = "Consumed Write Capacity Units"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    datapoints_to_alarm = null
    threshold           = 10 #TODO this threashold should be equal to the Write Capacy Unit.
    period              = 300
    unit                = "Count"

    namespace   = "AWS/DynamoDB"
    metric_name = "ConsumedWriteCapacityUnits"
    statistic   = "Maximum"
  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-read-throttle-events"
    alarm_description   = "Consumed Read Throttle Events"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    datapoints_to_alarm = null
    threshold           = 10 #TODO this threashold should be equal to the Write Capacy Unit.
    period              = 300
    unit                = "Count"

    namespace   = "AWS/DynamoDB"
    metric_name = "ReadThrottleEvents"
    statistic   = "Maximum"
  },
  {
    actions_enabled     = true
    alarm_name          = "dynamodb-write-throttle-events"
    alarm_description   = "Consumed Write Throttle Events"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2
    datapoints_to_alarm = null
    threshold           = 10 #TODO this threashold should be equal to the Write Capacy Unit.
    period              = 300
    unit                = "Count"

    namespace   = "AWS/DynamoDB"
    metric_name = "WriteThrottleEvents"
    statistic   = "Maximum"
  },
]

tags = {
  CreatedBy   = "Terraform"
  Environment = "Dev"
  Owner       = "Tokenizer Data Vault"
  Source      = "https://github.com/pagopa/pdv-tokenizer-infra"
  CostCenter  = "TS310 - PAGAMENTI e SERVIZI"
}
