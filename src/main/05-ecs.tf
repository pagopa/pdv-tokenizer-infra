# Cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = format("%s-ecs-cluster", local.project)
  tags = { Name = format("%s-ecs", local.project) }

  setting {
    name  = "containerInsights"
    value = var.enable_container_insights ? "enabled" : "diabled"
  }

}

locals {
  service_ids = [
    join("/", ["service", aws_ecs_cluster.ecs_cluster.name, aws_ecs_service.tokenizer.name, ]),
  ]
}

## Autoscaling
resource "aws_appautoscaling_target" "ecs_target" {
  count              = length(local.service_ids)
  max_capacity       = var.ecs_autoscaling.max_capacity
  min_capacity       = var.ecs_autoscaling.min_capacity
  resource_id        = local.service_ids[count.index]
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  count              = length(local.service_ids)
  name               = format("%s-memory-autoscaling", element(split("/", local.service_ids[count.index]), 2))
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {

    scale_in_cooldown  = var.ecs_autoscaling.scale_in_cooldown
    scale_out_cooldown = var.ecs_autoscaling.scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 70
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  count              = length(local.service_ids)
  name               = format("%s-cpu-autoscaling", element(split("/", local.service_ids[count.index]), 2))
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[count.index].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[count.index].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[count.index].service_namespace

  target_tracking_scaling_policy_configuration {

    scale_in_cooldown  = var.ecs_autoscaling.scale_in_cooldown
    scale_out_cooldown = var.ecs_autoscaling.scale_out_cooldown
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 70
  }
}