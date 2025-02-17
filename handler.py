import json
import boto3
import os

ec2 = boto3.client('ec2', region_name="us-west-2")

INSTANCE_ID = os.environ['EC2_ID']  # Add instance ID to environment variable EC2_ID

def lambda_handler(event, context):
    print("Received event:", json.dumps(event)) 

    action = ""
    if "queryStringParameters" in event and event["queryStringParameters"] is not None:
        action = event["queryStringParameters"].get("action", "").lower()
    elif "action" in event and event["action"] is not None:
        action = event.get("action", "").lower()
    
    if action not in ["start", "stop", "status"]:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid action. Use 'start', 'stop', or 'status'."})
        }

    try:
        if action == "start":
            ec2.start_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} is starting."

        elif action == "stop":
            ec2.stop_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} is stopping."

        elif action == "status":
            response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
            state = response["Reservations"][0]["Instances"][0]["State"]["Name"]
            message = f"Instance {INSTANCE_ID} is currently {state}."

        return {
            "statusCode": 200,
            "body": json.dumps({"message": message})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }