import base64
import json
import os
from datetime import datetime, timezone

import boto3

sns_client = boto3.client("sns")
s3_client = boto3.client("s3")

SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN")
S3_BUCKET = os.environ.get("S3_BUCKET")


def handler(event, context):
    records = event.get("records", {})
    messages = []
    for partition_records in records.values():
        for record in partition_records:
            raw = base64.b64decode(record["value"]).decode("utf-8")
            messages.append(json.loads(raw))

    for data in messages:
        sensor_id = data.get("sensorId", "unknown")
        timestamp = data.get("timestamp", datetime.now(timezone.utc).isoformat())
        alert_reason = data.get("alert_reason", "Unknown alert")

        if SNS_TOPIC_ARN:
            sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=f"[ALERT] Sensor {sensor_id}",
                Message=json.dumps({
                    "sensorId": sensor_id,
                    "timestamp": timestamp,
                    "alert_reason": alert_reason,
                    "data": data,
                }),
            )

        if S3_BUCKET:
            date_str = timestamp[:10]
            ts_safe = timestamp.replace(":", "-").replace("+", "p")
            s3_key = f"alert/{sensor_id}/{date_str}/{ts_safe}.json"
            s3_client.put_object(
                Bucket=S3_BUCKET,
                Key=s3_key,
                Body=json.dumps(data, ensure_ascii=False).encode("utf-8"),
                ContentType="application/json",
            )

    return {"statusCode": 200, "processed": len(messages)}
