import json
import os
import urllib.parse

import boto3

sf_client = boto3.client("stepfunctions")

STATE_MACHINE_ARN = os.environ.get("STATE_MACHINE_ARN")


def lambda_handler(event, context):
    for record in event.get("Records", []):
        bucket = record["s3"]["bucket"]["name"]
        key = urllib.parse.unquote_plus(record["s3"]["object"]["key"])

        if not key.startswith("input/") or not key.endswith(".csv"):
            continue

        sf_client.start_execution(
            stateMachineArn=STATE_MACHINE_ARN,
            input=json.dumps({
                "key": key,
                "bucket": bucket,
            }),
        )

    return {"statusCode": 200}
