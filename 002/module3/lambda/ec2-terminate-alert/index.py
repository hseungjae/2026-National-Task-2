import json
import os
from datetime import datetime, timezone

import boto3

sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")


def handler(event, context):
    detail = event.get("detail", {})
    instance_id = detail.get("instance-id", "unknown")

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            "event": "EC2_TERMINATED",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "detail": f"EC2 instance {instance_id} was terminated",
            "action": "ALERT_ONLY",
        }),
    )
