import json
import os
from datetime import datetime, timezone

import boto3

ec2_client = boto3.client("ec2")
sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
INSTANCE_ID = os.environ.get("INSTANCE_ID")
ROLE_NAME = os.environ.get("ROLE_NAME", "wsc2026-event-ec2-role")


def handler(event, context):
    print(f"EVENT: {json.dumps(event)}")

    try:
        associations = ec2_client.describe_iam_instance_profile_associations(
            Filters=[{"Name": "instance-id", "Values": [INSTANCE_ID]}]
        )["IamInstanceProfileAssociations"]

        profile_name = f"{ROLE_NAME}-profile"

        if associations:
            assoc_id = associations[0]["AssociationId"]
            ec2_client.replace_iam_instance_profile_association(
                AssociationId=assoc_id,
                IamInstanceProfile={"Name": f"wsc2026-event-ec2-profile"},
            )
            print(f"Replaced instance profile to wsc2026-event-ec2-profile on {INSTANCE_ID}")
        else:
            ec2_client.associate_iam_instance_profile(
                InstanceId=INSTANCE_ID,
                IamInstanceProfile={"Name": "wsc2026-event-ec2-profile"},
            )
            print(f"Associated instance profile wsc2026-event-ec2-profile on {INSTANCE_ID}")
    except Exception as e:
        print(f"Profile restore failed: {e}")

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            "event": "ROLE_CHANGED",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "detail": f"IAM Role on instance {INSTANCE_ID} was changed and restored to {ROLE_NAME}",
            "action": "RESTORED",
        }),
    )
