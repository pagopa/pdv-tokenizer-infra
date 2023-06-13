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

resource "aws_sqs_queue" "target" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = format("queue-%s-tokens", var.env_short)
}

resource "aws_sqs_queue_policy" "target" {
  count     = var.create_event_bridge_pipe && length(var.sqs_consumer_principals) > 0 ? 1 : 0
  queue_url = aws_sqs_queue.target[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.sqs_consumer_principals
        },
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ],
        Resource = aws_sqs_queue.target[0].arn
      },
    ]
  })
}

resource "aws_iam_role_policy" "target" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "AllowPipeWriteSQS"

  role = aws_iam_role.pipe[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ],
        Resource = [
          aws_sqs_queue.target[0].arn,
        ]
      },
    ]
  })
}

resource "aws_pipes_pipe" "token" {
  count         = var.create_event_bridge_pipe ? 1 : 0
  depends_on    = [aws_iam_role_policy.source, aws_iam_role_policy.target]
  name          = format("pipe-%s-tokens", var.env_short)
  role_arn      = aws_iam_role.pipe[0].arn
  source        = module.dynamodb_table_token.dynamodb_table_stream_arn
  target        = aws_sqs_queue.target[0].arn
  desired_state = var.event_bridge_desired_state

  source_parameters {
    filter_criteria {
      filter {
        pattern = jsonencode({
          dynamodb = {
            Keys = {
              SK = {
                S = [
                  {
                    anything-but = "GLOBAL"
                  },
                ]
              }
            }
          }
        })
      }
    }
  }

  target_parameters {
    input_template = <<-EOT
{
    "eventID": <$.eventID>, 
    "eventName": <$.eventName>, 
    "SK": <$.dynamodb.NewImage.SK.S>,
    "globalToken": <$.dynamodb.NewImage.globalToken.S>,
    "token": <$.dynamodb.NewImage.token.S>
}
EOT
  }
}
