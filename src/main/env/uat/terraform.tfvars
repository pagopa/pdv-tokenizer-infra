env_short   = "u"
environment = "uat"

# Network
enable_nat_gateway = false

## Vpc peering
vpc_peering = {
  owner_connection_id = "pcx-01c148625db1c0c0e"
  owner_cidr_block    = "10.0.0.0/16"
}

# Ecs
ecs_enable_execute_command = true

replica_count              = 3
ecs_logs_retention_days    = 90
tokenizer_image_version    = "851cd421296e00c50bb5ff792e73b97483c11920"
tokenizer_container_cpu    = 1024
tokenizer_container_memory = 2048

ecs_autoscaling = {
  max_capacity       = 6
  min_capacity       = 3
  scale_in_cooldown  = 900 # 15 min  
  scale_out_cooldown = 60
}

enable_container_insights = true

# Public DNS Zone.

public_dns_zones = {
  "uat.tokenizer.pdv.pagopa.it" = {
    comment = "Personal data vault (Uat)"
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
    burst_limit     = 5
    rate_limit      = 10
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "SELFCARE-DEV"
    burst_limit     = 5
    rate_limit      = 10
    additional_keys = ["INTEROP-DEV"]
    method_throttle = []
  },
  {
    key_name        = "IOSIGN"
    burst_limit     = 5
    rate_limit      = 10
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "USERREGISTRY"
    burst_limit     = 5
    rate_limit      = 10
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "SELFCARE-UAT"
    burst_limit     = 5
    rate_limit      = 10
    additional_keys = ["INTEROP-UAT"]
    method_throttle = []
  },
  {
    key_name        = "PNPF-DEV"
    burst_limit     = 5
    rate_limit      = 10
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "PNPF-UAT"
    burst_limit     = 10
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "PNPF-CERT"
    burst_limit     = 10
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  {
    # Piattaforma Notifiche Persone Giuridiche
    key_name        = "PNPG"
    burst_limit     = 10
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "IDPAY-DEV"
    burst_limit     = 50
    rate_limit      = 150
    additional_keys = []
    method_throttle = []
  },
  {
    key_name        = "IDPAY-UAT"
    burst_limit     = 50
    rate_limit      = 300
    additional_keys = []
    method_throttle = []
  },
  ## PagoPa Ecommerce
  {
    key_name        = "PPAECOM"
    burst_limit     = 50
    rate_limit      = 100
    additional_keys = []
    method_throttle = []
  },
]


# dynamodb
dynamodb_point_in_time_recovery_enabled = false


## table Token
table_token_read_capacity  = 20
table_token_write_capacity = 50

table_token_stream_enabled = false

table_token_autoscaling_read = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 50 # target utilisation %
  max_capacity       = 250
}

table_token_autoscaling_write = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 50 # target utilisation %
  max_capacity       = 80
}

table_token_autoscling_indexes = {
  gsi_token = {
    read_max_capacity  = 250
    read_min_capacity  = 20
    write_max_capacity = 50
    write_min_capacity = 10
  }
}

## Event bridge
create_event_bridge_pipe = true

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
  Environment = "Uat"
  Owner       = "Tokenizer Data Vault"
  Source      = "https://github.com/pagopa/pdv-tokenizer-infra"
  CostCenter  = "TS310 - PAGAMENTI e SERVIZI"
}
