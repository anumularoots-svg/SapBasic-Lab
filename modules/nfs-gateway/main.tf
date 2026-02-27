variable "project_name"      { type = string }
variable "instance_type"     { type = string }
variable "ami_id"            { type = string }
variable "key_name"          { type = string }
variable "private_subnet_id" { type = string }
variable "vpc_id"            { type = string }
variable "vpc_cidr"          { type = string }
variable "environment"       { type = string }

resource "aws_security_group" "nfs_gw" {
  name_prefix = "${var.project_name}-nfs-gw-"
  vpc_id      = var.vpc_id
  description = "NFS Gateway — NFS + SSH"

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "NFS from VPC"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "SSH"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-nfs-gw-sg" }
  lifecycle { create_before_destroy = true }
}

resource "aws_instance" "nfs_gateway" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.nfs_gw.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "${var.project_name}-nfs-gateway" }
}

output "private_ip"         { value = aws_instance.nfs_gateway.private_ip }
output "instance_id"        { value = aws_instance.nfs_gateway.id }
output "security_group_id"  { value = aws_security_group.nfs_gw.id }
