locals {
  # Token
  dynamodb_table_token  = "Token"
  dynamo_gsi_token_name = "gsi_token"
}

# Table Token
module "dynamodb_table_token" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "3.3.0"


  name                           = local.dynamodb_table_token
  hash_key                       = "PK"
  range_key                      = "SK"
  stream_enabled                 = var.table_token_stream_enabled
  stream_view_type               = var.table_token_stream_enabled ? "NEW_IMAGE" : null
  point_in_time_recovery_enabled = var.dynamodb_point_in_time_recovery_enabled
  billing_mode                   = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "PK"
      type = "S"
    },
    {
      name = "SK"
      type = "S"
    },
    {
      name = "token"
      type = "S"
    },
  ]

  global_secondary_indexes = [
    {
      name            = local.dynamo_gsi_token_name
      hash_key        = "token"
      projection_type = "ALL"
    }
  ]


  server_side_encryption_enabled     = true
  server_side_encryption_kms_key_arn = aws_kms_alias.dynamo_db.target_key_arn

  replica_regions = var.dynamodb_region_replication_enable ? [{
    region_name = "eu-central-1"
    kms_key_arn = aws_kms_alias.dynamo_db_replica[0].target_key_arn
  }] : []


  tags = { Name = local.dynamodb_table_token }
}