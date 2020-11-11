variable region {
  type        = string
  description = "AWS Region the Fargate service is deployed to"
}

variable "namespace" {
  type = string
}

variable env {
  type        = string
  description = "Environment this Fargate service belongs to. Prod should be used for production"
}

variable "tags" {
  type        = map(string)
  description = "A set of tags that will be applied to all resources created by this module"
}

variable fargate_service_name {
  type        = string
  description = "Fargate service name"
}

variable slack_webhook_url {
  type        = string
  description = "Slack webhook URL for Cloudwatch alarm notifications"
}

variable "alb_ref_and_target_groups_to_monitor" {
  type        = map(string)
  description = "A map representing alb references in the format /loadbalancer/{name} and target group suffixes that will be monitored with cloudwatch"
}

variable "create_connection_error_alarm" {
  type        = bool
  default     = false
  description = "Set to true if connection error alarm should be created"
}

variable "create_target_response_time_alarm" {
  type        = bool
  default     = false
  description = "Set to true if target response time alarm should be created"
}

variable "create_unhealthy_host_count_alarm" {
  type        = bool
  default     = false
  description = "Set to true if unhealthy host count alarm should be created"
}

variable "create_request_count_alarm" {
  type        = bool
  default     = false
  description = "Set to true if request count alarm should be created"
}

variable "create_success_responses_alarm" {
  type        = bool
  default     = false
  description = "Set to true if success responses alarm should be created"
}

variable "alarm_data_missing_action" {
  type        = string
  default     = "missing"
  description = "Missing data action for success responses alarm. Possible values: missing or breaching"
}

variable monit_resp_success_percentage {
  type        = string
  default     = "99"
  description = "What percentage of requests should be responded to with 2xx"
}

variable "monit_target_response_time" {
  type        = string
  default     = "0.5"
  description = "service response time in seconds greater than or equal to"
}

variable "desired_count" {
  type        = number
  description = "desired number of container instances running"
}