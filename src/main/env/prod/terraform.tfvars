env_short   = "p"
environment = "prod"

# Network
enable_nat_gateway = false

## Vpc peering

vpc_peering = {
  owner_connection_id = "pcx-047ec6e6db9a0c433"
  owner_cidr_block    = "10.0.0.0/16"
}


# Ecs
ecs_enable_execute_command = true
replica_count              = 3
ecs_logs_retention_days    = 90
tokenizer_image_version    = "28fb0d05d0f1b175e7e978a007d193e88f0dc228"
tokenizer_container_cpu    = 1024
tokenizer_container_memory = 2048

ms_tokenizer_enable_confidential_filter = true
ms_tokenizer_log_level                  = "INFO"

ecs_autoscaling = {
  max_capacity       = 10
  min_capacity       = 3
  scale_in_cooldown  = 900
  scale_out_cooldown = 60
}

enable_container_insights = true


# Public DNS Zone 

public_dns_zones = {
  "tokenizer.pdv.pagopa.it" = {
    comment = "Personal data vault (Prod)"
  }
}

# App
ms_tokenizer_enable_single_line_stack_trace_logging = true


# Api Gateway 

apigw_custom_domain_create     = true
apigw_access_logs_enable       = false
apigw_execution_logs_retention = 90

## Throttling 
tokenizer_plans = [{
  key_name        = "SELFCARE"
  burst_limit     = 400
  rate_limit      = 200
  additional_keys = ["INTEROP"]
  method_throttle = []
  },
  {
    key_name        = "USERREGISTRY"
    burst_limit     = 200
    rate_limit      = 100
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "TEST"
    burst_limit     = 200
    rate_limit      = 100
    additional_keys = []
    method_throttle = []
  },
  {
    # Piattaforma notifiche
    key_name        = "PNPF"
    burst_limit     = 600
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  {
    # Piattaforma notifiche persone giuridiche.
    key_name        = "PNPG"
    burst_limit     = 600
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "IDPAY"
    burst_limit     = 600
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "IOSIGN"
    burst_limit     = 400
    rate_limit      = 200
    additional_keys = []
    method_throttle = []
  },
  ## PagoPa Ecommerce
  {
    key_name        = "PPAECOM"
    burst_limit     = 200
    rate_limit      = 100
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
  {
    key_name        = "RICEVUTEPPA"
    burst_limit     = 300
    rate_limit      = 200
    additional_keys = []
    method_throttle = []
  },
]

## Web ACL

web_acl_visibility_config = {
  cloudwatch_metrics_enabled = true
  sampled_requests_enabled   = true
}

# dynamodb
dynamodb_point_in_time_recovery_enabled = true


## table Token
table_token_read_capacity  = 50
table_token_write_capacity = 300

table_token_autoscaling_read = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 50 # target utilisation %
  max_capacity       = 200
}

table_token_autoscaling_write = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 50 # target utilisation %
  max_capacity       = 600
}

table_token_autoscling_indexes = {
  gsi_token = {
    read_min_capacity  = 20
    read_max_capacity  = 100
    write_min_capacity = 200
    write_max_capacity = 400

  }
}

## alarms

enable_opsgenie = true

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
  Environment = "Prod"
  Owner       = "Tokenizer Data Vault"
  Source      = "https://github.com/pagopa/pdv-tokenizer-infra"
  CostCenter  = "TS310 - PAGAMENTI e SERVIZI"
}
