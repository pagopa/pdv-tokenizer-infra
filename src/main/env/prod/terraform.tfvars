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
replica_count              = 2
ecs_logs_retention_days    = 90

ecs_autoscaling = {
  max_capacity       = 5
  min_capacity       = 2
  scale_in_cooldown  = 180
  scale_out_cooldown = 40
}


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
  key_name    = "SELFCARE"
  burst_limit = 5
  rate_limit  = 100
  method_throttle = [
    {
      burst_limit = 5
      path        = "/tokens/PUT"
      rate_limit  = 65
    },
    {
      burst_limit = 5
      path        = "/tokens/{token}/pii/GET"
      rate_limit  = 32
    },
    {
      burst_limit = 5
      path        = "/tokens/search/POST"
      rate_limit  = 38
    },
  ]
  },
  {
    key_name    = "INTEROP"
    burst_limit = 5
    rate_limit  = 100
    method_throttle = [
      {
        burst_limit = 5
        path        = "/tokens/PUT"
        rate_limit  = 65
      },
      {
        burst_limit = 5
        path        = "/tokens/{token}/pii/GET"
        rate_limit  = 32
      },
      {
        burst_limit = 5
        path        = "/tokens/search/POST"
        rate_limit  = 38
      },
    ]
  },
  {
    key_name    = "USERREGISTRY"
    burst_limit = 5
    rate_limit  = 100
    method_throttle = [
      {
        burst_limit = 5
        path        = "/tokens/PUT"
        rate_limit  = 65
      },
      {
        burst_limit = 5
        path        = "/tokens/{token}/pii/GET"
        rate_limit  = 32
      },
      {
        burst_limit = 5
        path        = "/tokens/search/POST"
        rate_limit  = 38
      },
    ]
  },
  {
    key_name    = "TEST"
    burst_limit = 5
    rate_limit  = 100
    method_throttle = [
      {
        burst_limit = 5
        path        = "/tokens/PUT"
        rate_limit  = 65
      },
      {
        burst_limit = 5
        path        = "/tokens/{token}/pii/GET"
        rate_limit  = 32
      },
      {
        burst_limit = 5
        path        = "/tokens/search/POST"
        rate_limit  = 38
      },
    ]
  },
  {
    # Piattaforma notifiche
    key_name    = "PNPF"
    burst_limit = 5
    rate_limit  = 100
    method_throttle = [
      {
        burst_limit = 5
        path        = "/tokens/PUT"
        rate_limit  = 65
      },
      {
        burst_limit = 5
        path        = "/tokens/{token}/pii/GET"
        rate_limit  = 32
      },
      {
        burst_limit = 5
        path        = "/tokens/search/POST"
        rate_limit  = 38
      },
    ]
  },
  {
    # Piattaforma notifiche persone giuridiche.
    key_name    = "PNPG"
    burst_limit = 5
    rate_limit  = 100
    method_throttle = [
      {
        burst_limit = 5
        path        = "/tokens/PUT"
        rate_limit  = 65
      },
      {
        burst_limit = 5
        path        = "/tokens/{token}/pii/GET"
        rate_limit  = 100
      },
      {
        burst_limit = 5
        path        = "/tokens/search/POST"
        rate_limit  = 38
      },
    ]
  },
  {
    key_name        = "IDPAY"
    burst_limit     = 50
    rate_limit      = 300
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
table_token_read_capacity  = 20
table_token_write_capacity = 50

table_token_autoscaling_read = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 70 # target utilisation %
  max_capacity       = 250
}

table_token_autoscaling_write = {
  scale_in_cooldown  = 300
  scale_out_cooldown = 40
  target_value       = 70 # target utilisation %
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

enable_sentinel_logs  = false
sentinel_workspace_id = "a6cbd2fb-37c2-4f23-bc46-311585b62a52"

tags = {
  CreatedBy   = "Terraform"
  Environment = "Prod"
  Owner       = "Tokenizer Data Vault"
  Source      = "https://github.com/pagopa/pdv-tokenizer-infra"
  CostCenter  = "TS310 - PAGAMENTI e SERVIZI"
}
