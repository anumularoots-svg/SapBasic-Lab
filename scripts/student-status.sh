#!/bin/bash
# student-status.sh — Show status of all student EC2s + WorkSpaces
set -e
REGION=${1:-us-east-1}

echo "══════════════════════════════════════════════════"
echo " SAP Training Lab — Student Server Status"
echo "══════════════════════════════════════════════════"
echo ""
echo "EC2 Instances:"
aws ec2 describe-instances \
  --filters 'Name=tag:Project,Values=sap-training-lab' \
  --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,IP:PrivateIpAddress,ID:InstanceId}' \
  --output table --region $REGION

echo ""
echo "WorkSpaces:"
aws workspaces describe-workspaces --region $REGION \
  --query 'Workspaces[].{User:UserName,State:State,IP:IpAddress,WsId:WorkspaceId}' \
  --output table

echo ""
RUNNING=$(aws ec2 describe-instances \
  --filters 'Name=tag:Project,Values=sap-training-lab' 'Name=instance-state-name,Values=running' \
  --query 'Reservations[].Instances[].InstanceId' --output text --region $REGION | wc -w)
STOPPED=$(aws ec2 describe-instances \
  --filters 'Name=tag:Project,Values=sap-training-lab' 'Name=instance-state-name,Values=stopped' \
  --query 'Reservations[].Instances[].InstanceId' --output text --region $REGION | wc -w)

echo "Summary: $RUNNING running | $STOPPED stopped"
