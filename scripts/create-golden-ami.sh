#!/bin/bash
# create-golden-ami.sh — Create Golden AMI from template EC2
set -e
REGION=${2:-us-east-1}

if [ -z "$1" ]; then
  echo "Usage: $0 <instance-id> [region]"
  echo "Example: $0 i-0abc123def456 us-east-1"
  exit 1
fi

INSTANCE_ID=$1
DATE=$(date +%Y%m%d-%H%M)
AMI_NAME="SAP-Basis-Golden-AMI-${DATE}"

echo "Stopping instance $INSTANCE_ID..."
aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --region $REGION
echo "Instance stopped."

echo "Creating AMI: $AMI_NAME..."
AMI_ID=$(aws ec2 create-image \
  --instance-id $INSTANCE_ID \
  --name "$AMI_NAME" \
  --description "SUSE 15 SP7 + SAP prereqs + NFS config + sapuser" \
  --region $REGION \
  --query 'ImageId' --output text)

echo ""
echo "══════════════════════════════════════"
echo " Golden AMI creating: $AMI_ID"
echo " Name: $AMI_NAME"
echo " This takes 10-30 minutes."
echo ""
echo " Update in your tfvars:"
echo "   golden_ami_id = \"$AMI_ID\""
echo "══════════════════════════════════════"
