variable "project_name"         { type = string }
variable "student_count"        { type = number }
variable "student_instance_ids" { type = list(string) }
variable "idle_timeout_minutes" { type = number }
variable "idle_cpu_threshold"   { type = number }
variable "aws_region"           { type = string }
variable "environment"          { type = string }

resource "aws_iam_role" "idle_stop" {
  name = "${var.project_name}-idle-stop-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "idle_stop" {
  name = "${var.project_name}-idle-stop-policy"
  role = aws_iam_role.idle_stop.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:DescribeInstances","ec2:StopInstances"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Resource = "*" }
    ]
  })
}

data "archive_file" "idle_stop" {
  type        = "zip"
  source_file = "${path.root}/lambda/ec2-stop-idle/handler.py"
  output_path = "${path.module}/idle_stop.zip"
}

resource "aws_lambda_function" "idle_stop" {
  function_name    = "${var.project_name}-idle-stop"
  role             = aws_iam_role.idle_stop.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.idle_stop.output_path
  source_code_hash = data.archive_file.idle_stop.output_base64sha256
  environment { variables = { REGION = var.aws_region } }
}

resource "aws_lambda_permission" "cw_alarm" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.idle_stop.function_name
  principal     = "lambda.alarms.cloudwatch.amazonaws.com"
}

# One alarm per student EC2
resource "aws_cloudwatch_metric_alarm" "idle" {
  count               = var.student_count
  alarm_name          = "${var.project_name}-idle-student${format("%02d", count.index + 1)}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.idle_timeout_minutes / 5
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.idle_cpu_threshold
  alarm_actions       = [aws_lambda_function.idle_stop.arn]
  dimensions          = { InstanceId = var.student_instance_ids[count.index] }
  treat_missing_data  = "notBreaching"
}
