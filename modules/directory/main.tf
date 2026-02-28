variable "project_name"       { type = string }
variable "directory_name"     { type = string }
variable "vpc_id"             { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "environment"        { type = string }

variable "admin_password" {
  type      = string
  sensitive = true
}

resource "aws_directory_service_directory" "simple_ad" {
  name     = var.directory_name
  password = var.admin_password
  size     = "Small"
  type     = "SimpleAD"

  vpc_settings {
    vpc_id     = var.vpc_id
    subnet_ids = var.private_subnet_ids
  }

  tags = { Name = "${var.project_name}-directory" }
}

resource "aws_workspaces_directory" "main" {
  directory_id = aws_directory_service_directory.simple_ad.id

  self_service_permissions {
    restart_workspace    = true
    increase_volume_size = false
    change_compute_type  = false
    switch_running_mode  = false
    rebuild_workspace    = false
  }

  workspace_access_properties {
    device_type_windows = "ALLOW"
    device_type_osx     = "ALLOW"
    device_type_web     = "ALLOW"
    device_type_linux   = "ALLOW"
  }

  tags = { Name = "${var.project_name}-ws-directory" }
}

output "directory_id"      { value = aws_directory_service_directory.simple_ad.id }
output "registration_code" { value = aws_workspaces_directory.main.registration_code }
output "dns_ips"           { value = aws_directory_service_directory.simple_ad.dns_ip_addresses }
output "directory_sg_id"   { value = tolist(aws_directory_service_directory.simple_ad.security_group_id)[0] }
