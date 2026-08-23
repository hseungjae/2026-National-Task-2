import json
import os
from datetime import datetime, timezone

import boto3

ec2_client = boto3.client("ec2")
sns_client = boto3.client("sns")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
SECURITY_GROUP_ID = os.environ.get("SECURITY_GROUP_ID")


def handler(event, context):
    print(f"EVENT: {json.dumps(event)}")
    detail = event.get("detail", {})

    event_name = detail.get("eventName", "")
    compliance = detail.get("newEvaluationResult", {}).get("complianceType", "")

    if event_name != "AuthorizeSecurityGroupIngress" and compliance != "NON_COMPLIANT":
        return

    try:
        ip_permissions = detail.get("requestParameters", {}).get("ipPermissions", {}).get("items", [])
        for perm in ip_permissions:
            revoke_perm = {
                "IpProtocol": perm.get("ipProtocol", "-1"),
            }
            if perm.get("fromPort") is not None:
                revoke_perm["FromPort"] = perm["fromPort"]
            if perm.get("toPort") is not None:
                revoke_perm["ToPort"] = perm["toPort"]

            ip_ranges = perm.get("ipRanges", {}).get("items", [])
            if ip_ranges:
                revoke_perm["IpRanges"] = [{"CidrIp": r["cidrIp"]} for r in ip_ranges]

            ec2_client.revoke_security_group_ingress(
                GroupId=SECURITY_GROUP_ID,
                IpPermissions=[revoke_perm],
            )
            print(f"Rule removed from {SECURITY_GROUP_ID}: {revoke_perm}")
    except Exception as e:
        print(f"Revoke skipped: {e}")

    sns_client.publish(
        TopicArn=SNS_TOPIC_ARN,
        Message=json.dumps({
            "event": "SG_INBOUND_ADDED",
            "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            "detail": f"Unauthorized inbound rule removed from {SECURITY_GROUP_ID}",
            "action": "RESTORED",
        }),
    )
