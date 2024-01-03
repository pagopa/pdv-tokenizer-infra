resource "aws_cloudwatch_log_group" "ecs_tokenizer" {
  name = format("ecs/%s", local.task_tokenizer_name)

  retention_in_days = var.ecs_logs_retention_days

  tags = {
    Name = local.task_tokenizer_name
  }
}

resource "aws_ecs_task_definition" "tokenizer" {
  family = local.task_tokenizer_name

  container_definitions = <<DEFINITION
[
  {
    "name": "${local.project}-container",
    "image": "${aws_ecr_repository.main[0].repository_url}:${var.tokenizer_image_version}",
    "cpu": ${var.task_cpu - var.x_ray_daemon_container_cpu},
    "memory": ${var.task_memory - var.x_ray_daemon_container_memory},
    "entryPoint": [],
    "essential": true,
    "command": [
        "--log-level",
        "error"
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_tokenizer.id}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${local.project}"
      }
    },
    "portMappings": [
      {
        "containerPort": ${var.container_port_tokenizer},
        "hostPort": ${var.container_port_tokenizer}
      }
    ],
    "environment": [
      {
        "name": "AWS_REGION",
        "value": "${var.aws_region}"
      },
      {
        "name": "APP_SERVER_PORT",
        "value": "${var.container_port_tokenizer}"
      },
      {
        "name": "APP_LOG_LEVEL",
        "value": "${var.ms_tokenizer_log_level}"
      },
      {
        "name": "ENABLE_CONFIDENTIAL_FILTER",
        "value": "${var.ms_tokenizer_enable_confidential_filter}"
      },
      {
        "name": "ENABLE_SINGLE_LINE_STACK_TRACE_LOGGING",
        "value": "${var.ms_tokenizer_enable_single_line_stack_trace_logging}"
      }
    ]
  },
  {
    "name": "${local.project}-xray-daemon-container",
    "image": "${aws_ecr_repository.main[1].repository_url}:${var.x_ray_daemon_image_version}",
    "cpu": ${var.x_ray_daemon_container_cpu},
    "memoryReservation": ${var.x_ray_daemon_container_memory},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.ecs_tokenizer.id}",
        "awslogs-region": "${var.aws_region}",
        "awslogs-stream-prefix": "${local.project}"
      }
    },
    "portMappings" : [
        {
            "containerPort": 2000,
            "protocol": "udp"
        }
    ]
  }
]
  DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution_task.arn
  task_role_arn            = aws_iam_role.ecs_execution_task.arn

  tags = { Name = format("%s-ecs-td", local.project) }
}

# AWS X-Ray sampling rule

resource "aws_xray_sampling_rule" "xray_sampling_rule_exclude_health_check" {
  rule_name      = "exclude-health-check-path"
  fixed_rate     = 0.0
  host           = "*"
  http_method    = "*"
  priority       = 1
  reservoir_size = 0
  resource_arn   = "*"
  service_name   = "*"
  service_type   = "*"
  url_path       = "/actuator/health"
  version        = 1
}

data "aws_ecs_task_definition" "tokenizer" {
  task_definition = aws_ecs_task_definition.tokenizer.family
}

# Service
resource "aws_ecs_service" "tokenizer" {
  name    = local.service_tokenizer_name
  cluster = aws_ecs_cluster.ecs_cluster.id
  task_definition = format("%s:%s",
    aws_ecs_task_definition.tokenizer.family,
    max(aws_ecs_task_definition.tokenizer.revision, data.aws_ecs_task_definition.tokenizer.revision)
  )
  launch_type            = "FARGATE"
  scheduling_strategy    = "REPLICA"
  desired_count          = var.replica_count
  force_new_deployment   = true
  enable_execute_command = var.ecs_enable_execute_command

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups = [
      # NLB
      aws_security_group.nsg_task.id

    ]
  }

  load_balancer {
    target_group_arn = module.nlb.target_group_arns[0]
    container_name   = format("%s-container", local.project)
    container_port   = var.container_port_tokenizer
  }

  depends_on = [module.nlb]

  tags = { Name : local.service_tokenizer_name }
}
