import boto3
import json
import os

ec2 = boto3.client("ec2", region_name=os.environ.get("REGION", "us-east-1"))
PROJECT = os.environ.get("PROJECT_TAG", "sap-training-lab")


def lambda_handler(event, context):
    params = event.get("queryStringParameters") or {}
    action = params.get("action", "status")
    student = params.get("student", "")

    if not student:
        return response(400, {"error": "Missing 'student' parameter"})

    resp = ec2.describe_instances(Filters=[
        {"Name": "tag:StudentId", "Values": [student]},
        {"Name": "tag:Project", "Values": [PROJECT]},
        {"Name": "instance-state-name", "Values": ["running", "stopped", "pending", "stopping"]},
    ])

    instances = [i for r in resp["Reservations"] for i in r["Instances"]]
    if not instances:
        return response(404, {"error": f"No server found for {student}"})

    inst = instances[0]
    inst_id = inst["InstanceId"]
    state = inst["State"]["Name"]
    ip = inst.get("PrivateIpAddress", "N/A")

    if action == "start":
        if state == "stopped":
            ec2.start_instances(InstanceIds=[inst_id])
            return response(200, {"message": f"Starting server for {student}. Wait 2-3 minutes.", "ip": ip, "state": "starting"})
        return response(200, {"message": f"Server already {state}", "ip": ip, "state": state})

    elif action == "stop":
        if state == "running":
            ec2.stop_instances(InstanceIds=[inst_id])
            return response(200, {"message": f"Stopping server for {student}.", "state": "stopping"})
        return response(200, {"message": f"Server already {state}", "state": state})

    else:
        return response(200, {"student": student, "state": state, "ip": ip, "instance_id": inst_id})


def response(code, body):
    return {"statusCode": code, "headers": {"Content-Type": "application/json"}, "body": json.dumps(body)}
