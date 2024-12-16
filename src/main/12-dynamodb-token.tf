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


  tags = {
    Name   = local.dynamodb_table_token
    Backup = var.env_short == "p" ? "True" : "False"
  }
}


# Backup role.
resource "aws_iam_role" "dynamodb_backup" {
  name = format("%s-dynamodb-backups", local.project)

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

# Required policy to backup dynamodb tables
resource "aws_iam_policy" "dynamodb_backup" {
  name        = "dynamodb-backup-policy"
  description = "Policy for AWS Backup to backup Dynamodb table."

  policy = jsonencode(
    {
      Version = "2012-10-17",
      Statement = [
        {
          Effect = "Allow",
          Action = [
            "dynamodb:DescribeTable",
            "dynamodb:CreateBackup"
          ],
          Resource = "arn:aws:dynamodb:*:*:table/*"
        },
        {
          Effect = "Allow",
          Action = [
            "dynamodb:DescribeBackup",
            "dynamodb:DeleteBackup"
          ],
          Resource = "arn:aws:dynamodb:*:*:table/*/backup/*"
        },
        {
          Effect = "Allow",
          Action = [
            "backup:DescribeBackupVault",
            "backup:CopyIntoBackupVault"
          ],
          Resource = "arn:aws:backup:*:*:backup-vault:*"
        },
        {
          Effect   = "Allow",
          Action   = "kms:DescribeKey",
          Resource = "*"
        },
        {
          Effect   = "Allow",
          Action   = "kms:CreateGrant",
          Resource = "*",
          "Condition" : {
            "Bool" : {
              "kms:GrantIsForAWSResource" : "true"
            }
          }
        },
        {
          Effect = "Allow",
          Action = [
            "tag:GetResources"
          ],
          Resource = "*"
        },
        {
          "Sid" : "DynamodbBackupPermissions",
          Effect = "Allow",
          Action = [
            "dynamodb:StartAwsBackupJob",
            "dynamodb:ListTagsOfResource"
          ],
          Resource = "arn:aws:dynamodb:*:*:table/*"
        }
      ]
  })
}

resource "aws_iam_role_policy" "backup" {
  name   = "${local.project}-aws-backup-dynamodb-role-policy" # Replace with your desired role policy name
  role   = aws_iam_role.backup.name
  policy = aws_iam_policy.backup.policy
}


module "backup" {
  count   = var.env_short == "p" ? 1 : 0
  source  = "pagopa/backup/aws"
  version = "1.3.4"

  name = "${local.dynamodb_table_token}-backup"

  iam_role_arn = aws_iam_role.example.arn

  selection_tag = {
    key   = "Backup"
    value = "True"
  }

  enable_vault_lock_governance = false

  backup_rule = [{
    rule_name         = "backup_weekly_rule"
    schedule          = "cron(0 2 ?  * 1 *)"
    start_window      = 60
    completion_window = 140
    lifecycle = {
      delete_after = 14
    },
    },
    {
      rule_name         = "backup_monthly_rule"
      schedule          = "cron(0 4 1 * ? *)"
      start_window      = 60
      completion_window = 140
      lifecycle = {
        delete_after = 365
      },
  }]

  create_sns_topic    = true
  backup_vault_events = ["BACKUP_JOB_FAILED", "BACKUP_JOB_EXPIRED", "S3_BACKUP_OBJECT_FAILED"]
}
