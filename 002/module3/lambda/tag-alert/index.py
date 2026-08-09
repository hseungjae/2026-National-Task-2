import json
import os
from datetime import datetime, timezone

import boto3

sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")


def handler(event, context):
    print(f"EVENT: {json.dumps(event)}")
    detail = event.get("detail", {})

    resource_id = detail.get("resourceId", "unknown")
    compliance_type = (
        detail.get("newEvaluationResult", {})
        .get("complianceType", "UNKNOWN")
    )

    if compliance_type != "NON_COMPLIANT":
        return

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            "event": "TAG_NON_COMPLIANT",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "detail": f"Resource {resource_id} is missing required tags",
            "action": "ALERT_ONLY",
        }),
    )
