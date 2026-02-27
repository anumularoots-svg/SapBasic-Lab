"""
EOD Stop — Stops ALL student EC2s and WorkSpaces.
Triggered by EventBridge at 8 PM IST (Mon-Fri).
"""
import boto3
import os

REGION = os.environ.get("REGION", "us-east-1")
PROJECT = os.environ.get("PROJECT_TAG", "sap-training-lab")


def lambda_handler(event, context):
    ec2 = boto3.client("ec2", region_name=REGION)
    ws = boto3.client("workspaces", region_name=REGION)

    # Stop all running student EC2s
    resp = ec2.describe_instances(Filters=[
        {"Name": "tag:AutoStop", "Values": ["true"]},
        {"Name": "tag:Project", "Values": [PROJECT]},
        {"Name": "instance-state-name", "Values": ["running"]},
    ])
    ec2_ids = [i["InstanceId"] for r in resp["Reservations"] for i in r["Instances"]]

    if ec2_ids:
        ec2.stop_instances(InstanceIds=ec2_ids)
        print(f"EOD: Stopped {len(ec2_ids)} EC2 instances")

    # Stop all available WorkSpaces
    ws_resp = ws.describe_workspaces()
    ws_ids = [w["WorkspaceId"] for w in ws_resp.get("Workspaces", []) if w["State"] == "AVAILABLE"]

    for ws_id in ws_ids:
        try:
            ws.stop_workspaces(StopWorkspaceRequests=[{"WorkspaceId": ws_id}])
        except Exception as e:
            print(f"Failed to stop WorkSpace {ws_id}: {e}")

    print(f"EOD: Stopped {len(ws_ids)} WorkSpaces")

    return {"ec2_stopped": len(ec2_ids), "ws_stopped": len(ws_ids)}
