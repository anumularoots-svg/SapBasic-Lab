variable "project_name"         { type = string }
variable "student_count"        { type = number }
variable "student_instance_ids" { type = list(string) }
variable "nfs_gateway_id"       { type = string }
variable "alert_email"          { type = string }
variable "aws_region"           { type = string }
variable "environment"          { type = string }

resource "aws_sns_topic" "alerts" {
  count = var.alert_email != "" ? 1 : 0
  name  = "${var.project_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# NFS Gateway health check
resource "aws_cloudwatch_metric_alarm" "nfs_gw_health" {
  alarm_name          = "${var.project_name}-nfs-gw-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_actions       = var.alert_email != "" ? [aws_sns_topic.alerts[0].arn] : []
  dimensions          = { InstanceId = var.nfs_gateway_id }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 24, height = 6
        properties = {
          title   = "Student EC2 — CPU Utilization"
          region  = var.aws_region
          metrics = [for i, id in var.student_instance_ids :
            ["AWS/EC2", "CPUUtilization", "InstanceId", id, { label = "Student${format("%02d", i+1)}" }]
          ]
          period = 300, stat = "Average"
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "NFS Gateway — Network"
          region  = var.aws_region
          metrics = [
            ["AWS/EC2", "NetworkIn",  "InstanceId", var.nfs_gateway_id],
            ["AWS/EC2", "NetworkOut", "InstanceId", var.nfs_gateway_id]
          ]
          period = 300
        }
      }
    ]
  })
}
