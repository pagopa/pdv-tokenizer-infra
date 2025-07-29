resource "aws_cloudwatch_log_group" "lambda" {
  count             = var.create_event_bridge_pipe ? 1 : 0
  name              = "/aws/lambda/${aws_lambda_function.ingestion_count[0].function_name}"
  retention_in_days = var.log_retention_days
  lifecycle {
    prevent_destroy = false
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_exec" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "lambda-athena-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
    }]
  })
}

# IAM policy for Athena and S3 access
resource "aws_iam_policy" "lambda_athena_policy" {
  count = var.create_event_bridge_pipe ? 1 : 0
  name  = "lambda-athena-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "${aws_cloudwatch_log_group.lambda[0].arn}:*"
      },
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Resource = ["${module.s3_tokens_bucket[0].s3_bucket_arn}/*", "${module.s3_tokens_bucket[0].s3_bucket_arn}", "${module.s3_athena_output_bucket[0].s3_bucket_arn}/*", "${module.s3_athena_output_bucket[0].s3_bucket_arn}"]
      },
      {
        Effect = "Allow",
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions"
        ],
        Resource = [
          "${aws_athena_workgroup.tokens_workgroup[0].arn}",
          "${aws_glue_catalog_database.tokens[0].arn}",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:catalog",
          "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/${aws_glue_catalog_database.tokens[0].name}/tokens"
        ]
      },
    ]
  })
}


# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  count      = var.create_event_bridge_pipe ? 1 : 0
  role       = aws_iam_role.lambda_exec[0].name
  policy_arn = aws_iam_policy.lambda_athena_policy[0].arn
}

# Archive the Lambda code
data "archive_file" "lambda_zip" {
  count       = var.create_event_bridge_pipe ? 1 : 0
  type        = "zip"
  source_dir  = "../lambda/ingestion_count/"
  output_path = "../lambda/builds/ingestion_count.zip"
}

# Lambda function
resource "aws_lambda_function" "ingestion_count" {
  count         = var.create_event_bridge_pipe ? 1 : 0
  function_name = "ingestion-count"
  role          = aws_iam_role.lambda_exec[0].arn
  handler       = "index.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60

  filename         = data.archive_file.lambda_zip[0].output_path
  source_code_hash = data.archive_file.lambda_zip[0].output_base64sha256
  environment {
    variables = {
      DATABASE      = aws_glue_catalog_database.tokens[0].name
      OUTPUT_BUCKET = module.s3_athena_output_bucket[0].s3_bucket_id
      TABLE_NAME    = "tokens"
      TOKENS_BUCKET = module.s3_tokens_bucket[0].s3_bucket_id
      WORKGROUP     = aws_athena_workgroup.tokens_workgroup[0].name
    }
  }
}
