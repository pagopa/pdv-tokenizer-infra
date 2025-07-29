resource "aws_iam_role" "pipe" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "pipe-tokens-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = {
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "pipes.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
      }
    }
  })
}


resource "aws_iam_role_policy" "source" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "AllowPipeConsumeStream"

  role = aws_iam_role.pipe[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:DescribeStream",
          "dynamodb:ListStreams"
        ],
        Resource = [
          module.dynamodb_table_token.dynamodb_table_stream_arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
        ],
        Resource = [
          aws_kms_alias.dynamo_db.target_key_arn
        ]
      },
    ]
  })
}

# resource "aws_sqs_queue" "target" {
#   count = var.create_event_bridge_pipe ? 1 : 0
#   name  = format("queue-%s-tokens", var.env_short)
# }

# resource "aws_sqs_queue_policy" "target" {
#   count     = var.create_event_bridge_pipe && length(var.sqs_consumer_principals) > 0 ? 1 : 0
#   queue_url = aws_sqs_queue.target[0].id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           AWS = var.sqs_consumer_principals
#         },
#         Action = [
#           "sqs:ReceiveMessage",
#           "sqs:DeleteMessage"
#         ],
#         Resource = aws_sqs_queue.target[0].arn
#       },
#     ]
#   })
# }

resource "aws_iam_role_policy" "target" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "AllowPipeWriteFirehose"

  role = aws_iam_role.pipe[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ],
        Resource = [
          "${aws_kinesis_firehose_delivery_stream.firehose[0].arn}",
        ]
      },
    ]
  })
}

module "s3_tokens_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  count   = var.create_event_bridge_pipe ? 1 : 0
  version = "3.15.2"

  bucket                   = format("bucket-%s-tokens", var.env_short)
  acl                      = "private"
  control_object_ownership = true
  object_ownership         = "ObjectWriter"
  versioning = {
    enabled = true
  }
}

resource "aws_iam_role" "firehose" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "firehose-tokens-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = ["sts:AssumeRole"],
        Principal = {
          "Service" : "firehose.amazonaws.com"
        },
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_s3" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "AllowFirehoseWriteS3"
  role  = aws_iam_role.firehose[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject"
        ],
        Resource = "${module.s3_tokens_bucket[0].s3_bucket_arn}/*"
      }
    ]
  })
}

resource "aws_pipes_pipe" "token" {
  count         = var.create_event_bridge_pipe ? 1 : 0
  depends_on    = [aws_iam_role_policy.source, aws_iam_role_policy.target]
  name          = format("pipe-%s-tokens", var.env_short)
  role_arn      = aws_iam_role.pipe[0].arn
  source        = module.dynamodb_table_token.dynamodb_table_stream_arn
  target        = aws_kinesis_firehose_delivery_stream.firehose[0].arn
  desired_state = var.event_bridge_desired_state

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "TRIM_HORIZON" # or "LATEST"
    }
  }

  target_parameters {
    input_template = <<-EOT
 { "eventID": <$.eventID>, "eventName": <$.eventName>, "SK": <$.dynamodb.NewImage.SK.S>, "globalToken": <$.dynamodb.NewImage.globalToken.S>, "token": <$.dynamodb.NewImage.token.S>}
EOT
  }
}

resource "aws_kinesis_firehose_delivery_stream" "firehose" {
  count       = var.create_event_bridge_pipe ? 1 : 0
  name        = format("firehose-%s-tokens", var.env_short)
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose[0].arn
    bucket_arn          = module.s3_tokens_bucket[0].s3_bucket_arn
    prefix              = "tokens/!{partitionKeyFromQuery:SK}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/!{firehose:error-output-type}/"

    buffering_size = 64

    processing_configuration {
      enabled = "true"
      processors {
        type = "AppendDelimiterToRecord"
      }

      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{SK:.SK}"
        }
      }
    }


    dynamic_partitioning_configuration {
      enabled = "true"
    }

    file_extension = ".json"
  }
}

module "s3_athena_output_bucket" {
  count   = var.create_event_bridge_pipe ? 1 : 0
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = format("bucket-%s-tokens-query", var.env_short)
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  tags = {
    Name = format("bucket-%s-tokens-query", var.env_short)
  }
}

resource "aws_athena_workgroup" "tokens_workgroup" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "tokens_workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${module.s3_athena_output_bucket[0].s3_bucket_id}/output/"
    }
  }
}

# Create Athena database
resource "aws_athena_database" "tokens" {
  count  = var.create_event_bridge_pipe ? 1 : 0
  name   = "tokens_db"
  bucket = module.s3_athena_output_bucket[0].s3_bucket_id
}

data "aws_iam_policy_document" "glue_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "glue_tokens" {
  count              = var.create_event_bridge_pipe ? 1 : 0
  name               = "AWSGlueServiceRole-Tokens-role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role_policy.json
  path               = "/service-role/"
}

data "aws_iam_policy_document" "glue_tokens_policy" {
  count = var.create_event_bridge_pipe ? 1 : 0
  statement {
    sid       = "S3ReadAndWrite"
    effect    = "Allow"
    resources = ["arn:aws:s3:::${module.s3_tokens_bucket[0].s3_bucket_id}/*"]
    actions   = ["s3:GetObject", "s3:PutObject"]
  }
}

resource "aws_iam_policy" "glue_tokens_policy" {
  count       = var.create_event_bridge_pipe ? 1 : 0
  name        = "AWSGlueServiceRoleTokensS3Policy"
  description = "S3 bucket tokens policy for glue."
  policy      = data.aws_iam_policy_document.glue_tokens_policy[0].json
}

locals {
  glue_tokens_policy = compact([
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole",
    var.create_event_bridge_pipe ? aws_iam_policy.glue_tokens_policy[0].arn : null
  ])
}

resource "aws_iam_role_policy_attachment" "glue_s3_tokens_policy" {
  count      = var.create_event_bridge_pipe ? length(local.glue_tokens_policy) : 0
  role       = aws_iam_role.glue_tokens[0].name
  policy_arn = local.glue_tokens_policy[count.index]
  depends_on = [aws_iam_policy.glue_tokens_policy]
}

resource "aws_glue_catalog_database" "tokens" {
  count = var.create_event_bridge_pipe == true ? 1 : 0
  name  = "tokens_catalog_db"
}

resource "aws_glue_crawler" "tokens" {
  count         = var.create_event_bridge_pipe == true ? 1 : 0
  database_name = aws_glue_catalog_database.tokens[0].name
  name          = "tokens_crawler"
  role          = aws_iam_role.glue_tokens[0].arn

  #schedule = var.tokens_crawler_schedule

  description = "Crawler for the tokens bucket"

  configuration = jsonencode(
    {
      CrawlerOutput = {
        Tables = {
          TableThreshold = 1
        }
      }
      CreatePartitionIndex = true
      Version              = 1.0
    }
  )

  s3_target {
    path = "s3://${module.s3_tokens_bucket[0].s3_bucket_id}/tokens/"
    exclusions = [
      "*/count/**"
    ]
  }
}
