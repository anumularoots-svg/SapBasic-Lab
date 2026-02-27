terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# ── Phase 1: Networking ──────────────────────────────────────
module "vpc" {
  source       = "./modules/vpc"
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  aws_region   = var.aws_region
  environment  = var.environment
}

# ── Phase 1: Simple AD ───────────────────────────────────────
module "directory" {
  source             = "./modules/directory"
  project_name       = var.project_name
  directory_name     = var.directory_name
  admin_password     = var.ad_admin_password
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  environment        = var.environment
}

# ── Phase 1: LDAP Users (student01..N) ───────────────────────
module "user_provisioner" {
  source             = "./modules/user-provisioner"
  project_name       = var.project_name
  student_count      = var.student_count
  student_password   = var.student_password
  directory_id       = module.directory.directory_id
  directory_name     = var.directory_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  directory_dns_ips  = module.directory.dns_ips
  environment        = var.environment
}

# ── Phase 3: WorkSpaces (Windows desktops) ───────────────────
module "workspaces" {
  source              = "./modules/workspaces"
  project_name        = var.project_name
  student_count       = var.student_count
  directory_id        = module.directory.directory_id
  workspace_bundle_id = var.workspace_bundle_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  environment         = var.environment
  depends_on          = [module.user_provisioner]
}

# ── NFS Gateway (re-export on-prem SAP software) ─────────────
module "nfs_gateway" {
  source            = "./modules/nfs-gateway"
  project_name      = var.project_name
  instance_type     = var.nfs_gateway_instance_type
  ami_id            = var.nfs_gateway_ami_id
  key_name          = var.key_name
  private_subnet_id = module.vpc.private_subnet_ids[0]
  vpc_id            = module.vpc.vpc_id
  vpc_cidr          = var.vpc_cidr
  environment       = var.environment
}

# ── Phase 4: Student EC2s (from Golden AMI) ──────────────────
module "student_ec2" {
  source                 = "./modules/student-ec2"
  project_name           = var.project_name
  student_count          = var.student_count
  golden_ami_id          = var.golden_ami_id
  instance_type          = var.student_instance_type
  key_name               = var.key_name
  private_subnet_id      = module.vpc.private_subnet_ids[0]
  vpc_id                 = module.vpc.vpc_id
  nfs_gateway_ip         = module.nfs_gateway.private_ip
  nfs_gateway_sg_id      = module.nfs_gateway.security_group_id
  workspace_subnet_cidrs = module.vpc.private_subnet_cidrs
  environment            = var.environment
}

# ── Phase 5: Self-Service API (start/stop from WorkSpace) ────
module "self_service" {
  source       = "./modules/self-service"
  project_name = var.project_name
  aws_region   = var.aws_region
  environment  = var.environment
}

# ── Phase 6: EOD Stop + Morning Start ────────────────────────
module "lambda_scheduler" {
  source               = "./modules/lambda-scheduler"
  project_name         = var.project_name
  aws_region           = var.aws_region
  eod_stop_cron        = var.eod_stop_cron
  morning_start_cron   = var.morning_start_cron
  enable_morning_start = var.enable_morning_start
  environment          = var.environment
}

# ── Phase 6: Idle Detection (per-EC2 CloudWatch alarm) ───────
module "lambda_idle_stop" {
  source               = "./modules/lambda-idle-stop"
  project_name         = var.project_name
  student_count        = var.student_count
  student_instance_ids = module.student_ec2.instance_ids
  idle_timeout_minutes = var.idle_timeout_minutes
  idle_cpu_threshold   = var.idle_cpu_threshold
  aws_region           = var.aws_region
  environment          = var.environment
}

# ── Monitoring ────────────────────────────────────────────────
module "monitoring" {
  source               = "./modules/monitoring"
  project_name         = var.project_name
  student_count        = var.student_count
  student_instance_ids = module.student_ec2.instance_ids
  nfs_gateway_id       = module.nfs_gateway.instance_id
  alert_email          = var.alert_email
  aws_region           = var.aws_region
  environment          = var.environment
}
