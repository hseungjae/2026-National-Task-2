import json
import os
from datetime import datetime, timezone

import boto3

ec2_client = boto3.client("ec2")
sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
INSTANCE_ID = os.environ.get("INSTANCE_ID")
INSTANCE_TYPE = os.environ.get("INSTANCE_TYPE", "t3.micro")


def handler(event, context):
    print(f"EVENT: {json.dumps(event)}")

    try:
        ec2_client.stop_instances(InstanceIds=[INSTANCE_ID])

        waiter = ec2_client.get_waiter("instance_stopped")
        waiter.wait(InstanceIds=[INSTANCE_ID])

        ec2_client.modify_instance_attribute(
            InstanceId=INSTANCE_ID,
            InstanceType={"Value": INSTANCE_TYPE},
        )

        ec2_client.start_instances(InstanceIds=[INSTANCE_ID])
        print(f"Instance {INSTANCE_ID} type restored to {INSTANCE_TYPE}")
    except Exception as e:
        print(f"Type restore failed: {e}")

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            "event": "EC2_TYPE_CHANGED",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "detail": f"Instance {INSTANCE_ID} type was changed and restored to {INSTANCE_TYPE}",
            "action": "RESTORED",
        }),
    )
