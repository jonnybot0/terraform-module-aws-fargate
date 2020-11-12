module "labels" {
  source  = "cloudposse/label/terraform"
  version = "0.5.0"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name
  tags      = var.tags
}


resource aws_security_group "this" {
  name_prefix = "${module.labels.id}-${var.name}-"
  vpc_id      = var.vpc_id

  egress {
    description      = "Egress"
    protocol         = var.protocol
    from_port        = 0
    to_port          = 0
    cidr_blocks      = var.sg_egress_cidr_blocks
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description     = "Load Balancer Ingress"
    from_port       = var.port
    protocol        = "TCP"
    to_port         = var.port
    security_groups = concat(var.ingress_sg_list, [var.alb_sg_id])
  }

  tags = module.labels.tags
}

resource aws_ecs_service "fargate" {
  name                               = "${module.labels.id}-${var.name}"
  task_definition                    = var.task_definition
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.min_healthy_percent
  deployment_maximum_percent         = var.max_percent
  cluster                            = var.ecs_cluster_arn
  launch_type                        = "FARGATE"
  platform_version                   = var.fargate_platform_version

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
    security_groups  = concat(var.sg_list, [aws_security_group.this.id])
  }

  dynamic load_balancer {
    for_each = toset(var.target_group_arns)
    content {
      target_group_arn = each
      container_name   = var.name
      container_port   = var.port
    }
  }

  tags = module.labels.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  region    = var.region
  env       = var.stage
  namespace = var.namespace
  tags      = module.labels.tags

  alb_ref_and_target_groups_to_monitor = var.alb_arn_and_target_groups_to_monitor

  fargate_service_name = aws_ecs_service.fargate.name
  desired_count        = var.desired_count

  slack_webhook_url                 = var.slack_webhook_url
  create_connection_error_alarm     = var.create_connection_error_alarm
  create_target_response_time_alarm = var.create_target_response_time_alarm
  create_unhealthy_host_count_alarm = var.create_unhealthy_host_count_alarm
  create_request_count_alarm        = var.create_request_count_alarm
  create_success_responses_alarm    = var.create_success_responses_alarm
  alarm_data_missing_action         = var.alarm_data_missing_action
  monit_resp_success_percentage     = var.monit_resp_success_percentage
  monit_target_response_time        = var.monit_target_response_time
}