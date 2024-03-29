data "aws_iam_policy_document" "ecs_tasks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution_task" {
  name               = format("%s-execution-task-role", local.project)
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role_policy.json
  tags               = { Name = format("%s-execution-task-role", local.project) }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecs_execution_task.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# policy to allow execute command.
resource "aws_iam_policy" "execute_command_policy" {
  count       = var.ecs_enable_execute_command ? 1 : 0
  name        = "PagoPaECSExecuteCommand"
  description = "Policy to allow ecs execute command."

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
         "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_execute_command_policy" {
  count      = var.ecs_enable_execute_command ? 1 : 0
  role       = aws_iam_role.ecs_execution_task.name
  policy_arn = aws_iam_policy.execute_command_policy[0].arn
}


## policy to allow ecs to read and write in dynamodb
resource "aws_iam_policy" "dynamodb_rw" {
  name        = "PagoPaECSReadWriteDynamoDB"
  description = "Policy to allow ecs tasks to read and write in dynamodb table"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:DeleteItem",
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:UpdateItem",
        "dynamodb:GetRecords"
      ],
      "Effect": "Allow",
      "Resource": [
        "${module.dynamodb_table_token.dynamodb_table_arn}",
        "${module.dynamodb_table_token.dynamodb_table_arn}/index/${local.dynamo_gsi_token_name}"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_dynamodb_rw" {
  role       = aws_iam_role.ecs_execution_task.name
  policy_arn = aws_iam_policy.dynamodb_rw.arn
}

## Allow ecs tasks to encrypt and decrypt KMS key
resource "aws_iam_policy" "ecs_allow_kms" {
  name        = "PagoPaAllowECSKMS"
  description = "Policy to allow ECS tasks to encrypt and decrypt data at rest in DynamoDB."

  policy = templatefile(
    "./iam_policies/allow-kms-encrypt-decrypt.json.tpl",
    {
      account_id = data.aws_caller_identity.current.account_id
    }
  )
}

resource "aws_iam_role_policy_attachment" "ecs_allow_kms" {
  role       = aws_iam_role.ecs_execution_task.name
  policy_arn = aws_iam_policy.ecs_allow_kms.arn
}

## Allow fargate task to query cloud hsm
## This action does not support resource-level permissions. Policies granting access must specify "*" ## in the resource element.
resource "aws_iam_policy" "ecs_allow_hsm" {
  count       = var.create_cloudhsm ? 1 : 0
  name        = "PagoPaAllowECSHSM"
  description = "Policy to allow ECS tasks query cloud hsm."

  policy = templatefile(
    "./iam_policies/allow-hsm.tpl.json", {}
  )
}

resource "aws_iam_role_policy_attachment" "ecs_allow_hsm" {
  count      = var.create_cloudhsm ? 1 : 0
  role       = aws_iam_role.ecs_execution_task.name
  policy_arn = aws_iam_policy.ecs_allow_hsm[0].arn
}

# grant ECS permissions to send trace on X-Ray
data "aws_iam_policy" "x_ray_daemon_write_access" {
  name = "AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy_attachment" "x_ray_daemon_write_access" {
  role       = aws_iam_role.ecs_execution_task.name
  policy_arn = data.aws_iam_policy.x_ray_daemon_write_access.arn
}

## IAM Group Developer
resource "aws_iam_group" "developers" {
  name = "Developers"
}

data "aws_iam_policy" "power_user" {
  name = "PowerUserAccess"
}

### Deny access to secret devops

data "aws_secretsmanager_secret" "devops" {
  name = "devops"
}

resource "aws_iam_policy" "deny_secrets_devops" {
  name        = "PagoPaDenyAccessSecretsDevops"
  description = "Deny access to devops secrets."

  policy = templatefile(
    "./iam_policies/deny-access-secret-devops.json.tpl",
    {
      secret_arn = data.aws_secretsmanager_secret.devops.arn
    }
  )
}

resource "aws_iam_group_policy_attachment" "power_user" {
  count      = var.env_short == "u" ? 1 : 0
  group      = aws_iam_group.developers.name
  policy_arn = data.aws_iam_policy.power_user.arn
}

resource "aws_iam_group_policy_attachment" "deny_secrets_devops" {
  count      = var.env_short == "u" ? 1 : 0
  group      = aws_iam_group.developers.name
  policy_arn = aws_iam_policy.deny_secrets_devops.arn
}

resource "aws_iam_policy" "deploy_ecs" {
  name        = "PagoPaECSDeploy"
  description = "Policy to allow deploy on ECS."

  policy = templatefile(
    "./iam_policies/deploy-ecs.json.tpl",
    {
      account_id            = data.aws_caller_identity.current.account_id
      execute_task_role_arn = aws_iam_role.ecs_execution_task.arn
    }
  )
}

data "aws_iam_policy" "ec2_ecr_full_access" {
  name = "AmazonEC2ContainerRegistryFullAccess"
}

## Deploy with github action
resource "aws_iam_role" "githubecsdeploy" {
  name        = "GitHubDeployECS"
  description = "Role to assume to create the infrastructure."


  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          "Federated" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" : [
              "repo:${var.github_tokenizer_repo}:*"
            ]
          },
          "ForAllValues:StringEquals" = {
            "token.actions.githubusercontent.com:iss" : "https://token.actions.githubusercontent.com",
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deploy_ecs" {
  role       = aws_iam_role.githubecsdeploy.name
  policy_arn = aws_iam_policy.deploy_ecs.arn
}

resource "aws_iam_role_policy_attachment" "deploy_ec2_ecr_full_access" {
  role       = aws_iam_role.githubecsdeploy.name
  policy_arn = data.aws_iam_policy.ec2_ecr_full_access.arn
}