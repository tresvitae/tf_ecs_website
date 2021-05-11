resource "aws_ecs_service" "web_app" {
  name            = "${var.project_name}--${var.environment}--service"
  cluster         = var.cluster_id # aws_ecs_cluster.ecs_cluster.id
  task_definition = var.task_arn # aws_ecs_task_definition.softserve.arn
  desired_count   = 2
  #iam_role        = aws_iam_role.ecs_agent.arn
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }

  load_balancer {
    target_group_arn = var.target_group # "${aws_alb_target_group.app.arn}"
    container_name   = "softserve"
    container_port   = 80
  }
}