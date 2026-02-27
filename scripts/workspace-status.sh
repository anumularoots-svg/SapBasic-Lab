#!/bin/bash
# workspace-status.sh — Quick WorkSpaces status check
REGION=${1:-us-east-1}
aws workspaces describe-workspaces --region $REGION \
  --query 'Workspaces[].{User:UserName,State:State,Mode:WorkspaceProperties.RunningMode}' \
  --output table
