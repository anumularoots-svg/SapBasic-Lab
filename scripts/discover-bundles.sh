#!/bin/bash
# discover-bundles.sh — Find available WorkSpaces bundles
REGION=${1:-us-east-1}
echo "Available WorkSpaces bundles in $REGION:"
aws workspaces describe-workspace-bundles --region $REGION \
  --query 'Bundles[].{ID:BundleId,Name:Name,Compute:ComputeType.Name,Root:RootStorage.Capacity,User:UserStorage.Capacity}' \
  --output table
