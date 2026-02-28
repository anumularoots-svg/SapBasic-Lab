variable "project_name"           { type = string }
variable "student_count"          { type = number }
variable "golden_ami_id"          { type = string }
variable "instance_type"          { type = string }
variable "key_name"               { type = string }
variable "private_subnet_id"      { type = string }
variable "vpc_id"                 { type = string }
variable "nfs_gateway_ip"         { type = string }
variable "nfs_gateway_sg_id"      { type = string }
variable "workspace_subnet_cidrs" { type = list(string) }
variable "environment"            { type = string }

# Security Group
resource "aws_security_group" "student_sap" {
  name_prefix = "${var.project_name}-student-sap-"
  vpc_id      = var.vpc_id
  description = "Student SAP servers - SSH, SAP GUI, HANA from WorkSpaces"

  dynamic "ingress" {
    for_each = var.workspace_subnet_cidrs
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SSH"
    }
  }

  dynamic "ingress" {
    for_each = var.workspace_subnet_cidrs
    content {
      from_port   = 3200
      to_port     = 3299
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SAP GUI"
    }
  }

  dynamic "ingress" {
    for_each = var.workspace_subnet_cidrs
    content {
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "HANA Studio"
    }
  }

  dynamic "ingress" {
    for_each = var.workspace_subnet_cidrs
    content {
      from_port   = 50013
      to_port     = 50014
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
      description = "SAP HTTP/S"
    }
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.nfs_gateway_sg_id]
    description     = "NFS"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-student-sap-sg" }
  lifecycle { create_before_destroy = true }
}

# EC2 Instances
resource "aws_instance" "student" {
  count                  = var.student_count
  ami                    = var.golden_ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.student_sap.id]

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    student_id     = format("%02d", count.index + 1)
    nfs_gateway_ip = var.nfs_gateway_ip
  }))

  tags = {
    Name      = "SAP-Student-${format("%02d", count.index + 1)}"
    StudentId = "student${format("%02d", count.index + 1)}"
    AutoStop  = "true"
    Project   = var.project_name
  }

  volume_tags = {
    Name = "SAP-Student-${format("%02d", count.index + 1)}"
  }
}

output "instance_ids" { value = aws_instance.student[*].id }

output "student_ip_map" {
  value = { for i, inst in aws_instance.student :
    "student${format("%02d", i + 1)}" => inst.private_ip }
}

output "student_id_map" {
  value = { for i, inst in aws_instance.student :
    "student${format("%02d", i + 1)}" => inst.id }
}

output "security_group_id" { value = aws_security_group.student_sap.id }
