# SAP Training Lab — AWS Infrastructure

Terraform automation for SAP Basis training lab: **Dedicated EC2 per student** + WorkSpaces + Auto-Stop + Self-Service.

## Architecture

```
Students (40) → WorkSpaces Client (Internet)
    │ WSP Protocol
    ▼
AWS WorkSpaces (x40) — Windows 10 — SAP GUI + PuTTY + "Start My Server"
    │ SSH/SAP GUI (private network)
    ▼
Dedicated EC2 per Student (x40) — m5.xlarge — SUSE Linux 15 SP7
    │ NFS (VPC)
    ▼
NFS Gateway EC2 — Re-exports on-prem SAP software
    │ SSH Tunnel
    ▼
On-Premise NFS Server — /jrktrainings/sapsoft (302 GB) + /hanabackup (20 GB)

Automation:
  EventBridge → Lambda (Stop all EC2s at 8 PM IST)
  EventBridge → Lambda (Start all EC2s at 9:30 AM IST)
  CloudWatch  → Lambda (Stop idle EC2 if CPU < 5% for 30 min)
  API Gateway → Lambda (Student self-service start/stop)
```

## Quick Start

### Prerequisites
- AWS CLI v2 configured
- Terraform >= 1.5.0
- Golden AMI created (see Phase 2 below)

### Phase 1: Deploy Foundation
```bash
terraform init
terraform apply -target=module.vpc -target=module.directory \
  -var-file=environments/poc.tfvars \
  -var="ad_admin_password=YourP@ss123"
```

### Phase 2: Create Golden AMI
1. Launch a SUSE 15 SP7 EC2 (m5.xlarge) in the private subnet
2. Configure SAP prerequisites (see docs/golden-ami-setup.md)
3. Create AMI: `./scripts/create-golden-ami.sh i-0xxxx us-east-1`
4. Update `golden_ami_id` in `environments/poc.tfvars`

### Phase 3: Deploy POC (5 Students)
```bash
terraform apply -var-file=environments/poc.tfvars \
  -var="ad_admin_password=YourP@ss123"
```

### Phase 4: Validate
```bash
./scripts/student-status.sh
```

### Phase 5: Scale to Production (40 Students)
```bash
terraform apply -var-file=environments/prod.tfvars \
  -var="ad_admin_password=YourP@ss123"
```

## Student Self-Service

Students use desktop shortcuts on their WorkSpace:
- **Start My Server** → Calls API Gateway → Lambda starts their EC2
- **Stop My Server** → Saves costs when done
- **Server Status** → Check if running

No AWS knowledge required. `%USERNAME%` auto-maps to their EC2.

## Cost Estimate

| Phase | Config | Monthly Cost |
|-------|--------|-------------|
| POC | 5 students | ~$488 |
| Production | 40 students (scheduled) | ~$3,183 |
| Production | 40 students (24/7) | ~$7,200 |
| **Savings** | | **56%** |

## Project Info

| Key | Value |
|-----|-------|
| AWS Account | 657246200133 |
| Region | us-east-1 |
| Registration Code | SLiad+WFCQRA |
| Directory | sap-lab.local |
| Terraform State | s3://lanciere-terraform-state-657246200133/sap-training-lab/ |
