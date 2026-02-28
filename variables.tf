variable "project_name" {
  type    = string
  default = "sap-training-lab"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "directory_name" {
  type    = string
  default = "sap-lab.local"
}

variable "ad_admin_password" {
  type      = string
  sensitive = true
}

variable "student_count" {
  type = number
}

variable "student_password" {
  type      = string
  default   = "Student@2026"
  sensitive = true
}

variable "workspace_bundle_id" {
  type = string
}

variable "golden_ami_id" {
  type = string
}

variable "student_instance_type" {
  type    = string
  default = "m5.xlarge"
}

variable "key_name" {
  type = string
}

variable "nfs_gateway_instance_type" {
  type    = string
  default = "t3.small"
}

variable "nfs_gateway_ami_id" {
  type = string
}

variable "eod_stop_cron" {
  type    = string
  default = "cron(30 14 ? * MON-FRI *)"
}

variable "morning_start_cron" {
  type    = string
  default = "cron(0 4 ? * MON-FRI *)"
}

variable "enable_morning_start" {
  type    = bool
  default = true
}

variable "idle_timeout_minutes" {
  type    = number
  default = 30
}

variable "idle_cpu_threshold" {
  type    = number
  default = 5
}

variable "alert_email" {
  type    = string
  default = ""
}
