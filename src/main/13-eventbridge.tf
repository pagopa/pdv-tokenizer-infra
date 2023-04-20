resource "aws_iam_role" "pipe" {

  name = "pipe-tokens-role"

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

  name = "AllowPipeConsumeStream"

  role = aws_iam_role.pipe.id
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
  name = format("queue-%s-tokens", var.env_short)
}

resource "aws_iam_role_policy" "target" {

  name = "AllowPipeWriteSQS"

  role = aws_iam_role.pipe.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
        ],
        Resource = [
          aws_sqs_queue.target.arn,
        ]
      },
    ]
  })
}

resource "aws_pipes_pipe" "token" {
  depends_on = [aws_iam_role_policy.source, aws_iam_role_policy.target]
  name       = format("pipe-%s-tokens", var.env_short)
  role_arn   = aws_iam_role.pipe.arn
  source     = module.dynamodb_table_token.dynamodb_table_stream_arn
  target     = aws_sqs_queue.target.arn

  source_parameters {}
  target_parameters {}
}
