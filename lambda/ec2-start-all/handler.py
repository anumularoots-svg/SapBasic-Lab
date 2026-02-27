"""
Morning Start — Starts ALL student EC2s.
Triggered by EventBridge at 9:30 AM IST (Mon-Fri).
"""
import boto3
import os

REGION = os.environ.get("REGION", "us-east-1")
PROJECT = os.environ.get("PROJECT_TAG", "sap-training-lab")


def lambda_handler(event, context):
    ec2 = boto3.client("ec2", region_name=REGION)

    resp = ec2.describe_instances(Filters=[
        {"Name": "tag:AutoStop", "Values": ["true"]},
        {"Name": "tag:Project", "Values": [PROJECT]},
        {"Name": "instance-state-name", "Values": ["stopped"]},
    ])
    ids = [i["InstanceId"] for r in resp["Reservations"] for i in r["Instances"]]

    if ids:
        ec2.start_instances(InstanceIds=ids)
        print(f"Morning: Started {len(ids)} EC2 instances")

    return {"started": len(ids)}
