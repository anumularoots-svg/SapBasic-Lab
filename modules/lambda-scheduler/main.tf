variable "project_name"         { type = string }
variable "aws_region"           { type = string }
variable "eod_stop_cron"        { type = string }
variable "morning_start_cron"   { type = string }
variable "enable_morning_start" { type = bool }
variable "environment"          { type = string }

# IAM
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-scheduler-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "scheduler" {
  name = "${var.project_name}-scheduler-policy"
  role = aws_iam_role.scheduler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:DescribeInstances","ec2:StartInstances","ec2:StopInstances"], Resource = "*" },
      { Effect = "Allow", Action = ["workspaces:DescribeWorkspaces","workspaces:StopWorkspaces"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Resource = "*" }
    ]
  })
}

# EOD Stop Lambda
data "archive_file" "eod_stop" {
  type        = "zip"
  source_file = "${path.root}/lambda/ec2-stop-all/handler.py"
  output_path = "${path.module}/eod_stop.zip"
}

resource "aws_lambda_function" "eod_stop" {
  function_name    = "${var.project_name}-eod-stop"
  role             = aws_iam_role.scheduler.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  filename         = data.archive_file.eod_stop.output_path
  source_code_hash = data.archive_file.eod_stop.output_base64sha256
  environment { variables = { PROJECT_TAG = var.project_name, REGION = var.aws_region } }
}

resource "aws_cloudwatch_event_rule" "eod_stop" {
  name                = "${var.project_name}-eod-stop"
  schedule_expression = var.eod_stop_cron
}

resource "aws_cloudwatch_event_target" "eod_stop" {
  rule = aws_cloudwatch_event_rule.eod_stop.name
  arn  = aws_lambda_function.eod_stop.arn
}

resource "aws_lambda_permission" "eod_stop" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.eod_stop.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.eod_stop.arn
}

# Morning Start Lambda
data "archive_file" "morning_start" {
  type        = "zip"
  source_file = "${path.root}/lambda/ec2-start-all/handler.py"
  output_path = "${path.module}/morning_start.zip"
}

resource "aws_lambda_function" "morning_start" {
  count            = var.enable_morning_start ? 1 : 0
  function_name    = "${var.project_name}-morning-start"
  role             = aws_iam_role.scheduler.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 120
  filename         = data.archive_file.morning_start.output_path
  source_code_hash = data.archive_file.morning_start.output_base64sha256
  environment { variables = { PROJECT_TAG = var.project_name, REGION = var.aws_region } }
}

resource "aws_cloudwatch_event_rule" "morning_start" {
  count               = var.enable_morning_start ? 1 : 0
  name                = "${var.project_name}-morning-start"
  schedule_expression = var.morning_start_cron
}

resource "aws_cloudwatch_event_target" "morning_start" {
  count = var.enable_morning_start ? 1 : 0
  rule  = aws_cloudwatch_event_rule.morning_start[0].name
  arn   = aws_lambda_function.morning_start[0].arn
}

resource "aws_lambda_permission" "morning_start" {
  count         = var.enable_morning_start ? 1 : 0
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.morning_start[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.morning_start[0].arn
}
