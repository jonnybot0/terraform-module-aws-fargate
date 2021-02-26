module "labels" {
  source  = "cloudposse/label/terraform"
  version = "0.5.0"

  namespace = var.namespace
  stage     = var.stage
  name      = var.name
  tags      = var.tags
}

locals {
  ingress_sg_list = var.alb_sg_id != "" ? concat(var.ingress_sg_list, [var.alb_sg_id]) : var.ingress_sg_list
}

resource "aws_security_group" "this" {

  name_prefix = "${module.labels.id}-"
  vpc_id      = var.vpc_id

  tags = module.labels.tags
}

resource "aws_security_group_rule" "egress" {
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  cidr_blocks       = var.sg_egress_cidr_blocks
  ipv6_cidr_blocks  = ["::/0"]
  type              = "egress"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "lb_ingress" {
  description       = "Load Balancer Ingress"
  from_port         = var.port
  protocol          = "TCP"
  to_port           = var.port
  security_groups   = local.ingress_sg_list
  type              = "ingress"
  security_group_id = aws_security_group.this.id
}

data "aws_ecs_task_definition" "this" {
  task_definition = var.task_definition
}

resource "aws_ecs_service" "fargate" {
  name                               = module.labels.id
  task_definition                    = "${data.aws_ecs_task_definition.this.family}:${data.aws_ecs_task_definition.this.revision}"
  desired_count                      = var.desired_count
  deployment_minimum_healthy_percent = var.min_healthy_percent
  deployment_maximum_percent         = var.max_percent
  cluster                            = var.ecs_cluster_arn
  launch_type                        = "FARGATE"
  platform_version                   = var.fargate_platform_version
  health_check_grace_period_seconds  = var.health_check_grace_period

  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = var.assign_public_ip
    security_groups  = concat(var.sg_list, [aws_security_group.this.id])
  }

  dynamic "load_balancer" {
    for_each = [for tg in toset(var.target_group_arns) : { arn = tg }]

    content {
      target_group_arn = load_balancer.value.arn
      container_name   = var.name
      container_port   = var.port
    }
  }

  wait_for_steady_state = var.wait_for_steady_state

  propagate_tags = "TASK_DEFINITION"
  tags           = module.labels.tags
}

module "monitoring" {
  source = "./modules/monitoring"

  region         = var.region
  env            = var.stage
  namespace      = var.namespace
  tags           = module.labels.tags
  include_region = var.include_region

  alb_and_target_groups_monitoring_dimensions = var.alb_and_target_groups_monitoring_dimensions

  fargate_service_name = aws_ecs_service.fargate.name
  desired_count        = var.desired_count

  enable_slack_notifications        = var.enable_slack_notifications
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
