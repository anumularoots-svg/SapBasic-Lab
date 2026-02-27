variable "project_name" { type = string }
variable "aws_region"   { type = string }
variable "environment"  { type = string }

# IAM
resource "aws_iam_role" "self_service" {
  name = "${var.project_name}-self-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "self_service" {
  name = "${var.project_name}-self-service-policy"
  role = aws_iam_role.self_service.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:DescribeInstances"], Resource = "*" },
      { Effect = "Allow",
        Action = ["ec2:StartInstances", "ec2:StopInstances"],
        Resource = "arn:aws:ec2:${var.aws_region}:*:instance/*",
        Condition = { StringEquals = { "aws:ResourceTag/Project" = var.project_name } } },
      { Effect = "Allow", Action = ["logs:CreateLogGroup","logs:CreateLogStream","logs:PutLogEvents"], Resource = "*" }
    ]
  })
}

# Lambda
data "archive_file" "self_service" {
  type        = "zip"
  source_file = "${path.root}/lambda/self-service/handler.py"
  output_path = "${path.module}/self_service.zip"
}

resource "aws_lambda_function" "self_service" {
  function_name    = "${var.project_name}-self-service"
  role             = aws_iam_role.self_service.arn
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  filename         = data.archive_file.self_service.output_path
  source_code_hash = data.archive_file.self_service.output_base64sha256
  environment { variables = { PROJECT_TAG = var.project_name, REGION = var.aws_region } }
}

# API Gateway (HTTP API)
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-self-service"
  protocol_type = "HTTP"
  cors_configuration { allow_origins = ["*"]; allow_methods = ["GET"] }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.self_service.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.self_service.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "api_url" { value = "${aws_apigatewayv2_stage.prod.invoke_url}/" }
