"""
Idle Stop — Triggered by CloudWatch alarm when EC2 CPU < 5% for 30 min.
Stops the specific idle EC2 instance.
"""
import boto3
import json
import os

REGION = os.environ.get("REGION", "us-east-1")


def lambda_handler(event, context):
    ec2 = boto3.client("ec2", region_name=REGION)

    # Extract instance ID from alarm
    if "detail" in event:
        # EventBridge format
        dimensions = event["detail"]["configuration"]["metrics"][0]["metricStat"]["metric"]["dimensions"]
        instance_id = dimensions.get("InstanceId")
    elif "alarmData" in event:
        # Direct alarm action format
        metrics = event["alarmData"]["configuration"]["metrics"]
        instance_id = metrics[0]["metricStat"]["metric"]["dimensions"].get("InstanceId")
    else:
        print(f"Unknown event format: {json.dumps(event)}")
        return {"error": "Unknown event format"}

    if instance_id:
        ec2.stop_instances(InstanceIds=[instance_id])
        print(f"Idle stop: {instance_id}")
        return {"stopped": instance_id}

    return {"error": "No instance ID found"}
