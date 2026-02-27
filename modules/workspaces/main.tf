variable "project_name"        { type = string }
variable "student_count"       { type = number }
variable "directory_id"        { type = string }
variable "workspace_bundle_id" { type = string }
variable "private_subnet_ids"  { type = list(string) }
variable "environment"         { type = string }

resource "aws_workspaces_workspace" "student" {
  count        = var.student_count
  directory_id = var.directory_id
  bundle_id    = var.workspace_bundle_id
  user_name    = "student${format("%02d", count.index + 1)}"

  workspace_properties {
    compute_type_name                         = "STANDARD"
    user_volume_size_gib                      = 50
    root_volume_size_gib                      = 80
    running_mode                              = "AUTO_STOP"
    running_mode_auto_stop_timeout_in_minutes = 10
  }

  tags = {
    Name      = "${var.project_name}-ws-student${format("%02d", count.index + 1)}"
    StudentId = "student${format("%02d", count.index + 1)}"
  }
}

output "workspace_ids" {
  value = { for i, ws in aws_workspaces_workspace.student :
    "student${format("%02d", i + 1)}" => ws.id }
}
