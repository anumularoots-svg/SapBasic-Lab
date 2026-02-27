variable "project_name"       { type = string }
variable "student_count"      { type = number }
variable "student_password"   { type = string; sensitive = true }
variable "directory_id"       { type = string }
variable "directory_name"     { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "directory_dns_ips"  { type = list(string) }
variable "environment"        { type = string }

resource "aws_iam_role" "provisioner" {
  name = "${var.project_name}-user-provisioner-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "provisioner" {
  name = "${var.project_name}-user-provisioner-policy"
  role = aws_iam_role.provisioner.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ds:*"], Resource = "*" },
      { Effect = "Allow", Action = ["ec2:CreateNetworkInterface","ec2:DescribeNetworkInterfaces","ec2:DeleteNetworkInterface"], Resource = "*" },
      { Effect = "Allow", Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Resource = "*" }
    ]
  })
}

resource "aws_security_group" "provisioner" {
  name_prefix = "${var.project_name}-provisioner-"
  vpc_id      = var.vpc_id
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "${var.project_name}-provisioner-sg" }
  lifecycle { create_before_destroy = true }
}

data "archive_file" "provisioner" {
  type        = "zip"
  source_file = "${path.root}/lambda/user-provisioner/handler.py"
  output_path = "${path.module}/user_provisioner.zip"
}

resource "aws_lambda_function" "provisioner" {
  function_name    = "${var.project_name}-user-provisioner"
  role             = aws_iam_role.provisioner.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 300
  filename         = data.archive_file.provisioner.output_path
  source_code_hash = data.archive_file.provisioner.output_base64sha256

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.provisioner.id]
  }

  environment {
    variables = {
      DIRECTORY_ID   = var.directory_id
      DIRECTORY_NAME = var.directory_name
      STUDENT_COUNT  = tostring(var.student_count)
      STUDENT_PWD    = var.student_password
      DNS_IPS        = join(",", var.directory_dns_ips)
    }
  }
}
