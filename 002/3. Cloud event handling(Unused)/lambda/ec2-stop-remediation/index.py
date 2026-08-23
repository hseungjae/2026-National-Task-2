import json
import os
from datetime import datetime, timezone

import boto3

ec2_client = boto3.client("ec2")
sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")


def handler(event, context):
    print(f"EVENT: {json.dumps(event)}")
    detail = event.get("detail", {})
    instance_id = detail.get("instance-id", "unknown")

    try:
        ec2_client.start_instances(InstanceIds=[instance_id])
        print(f"Instance {instance_id} restart requested")
    except Exception as e:
        print(f"Restart failed: {e}")

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            "event": "EC2_STOPPED",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "detail": f"EC2 instance {instance_id} was stopped and restart was requested",
            "action": "RESTORED",
        }),
    )
