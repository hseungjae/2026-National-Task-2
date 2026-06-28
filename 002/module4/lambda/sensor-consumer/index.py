import base64
import json
import os

import boto3

dynamodb = boto3.resource("dynamodb")
sns_client = boto3.client("sns")

DDB_TABLE = os.environ.get("DDB_TABLE", "wsc2026-sensor-data")
ALERT_TOPIC_ARN = os.environ.get("ALERT_TOPIC_ARN")


def detect_anomaly(temperature, humidity):
    temp = float(temperature)
    hum = float(humidity)

    if temp > 80:
        return "ALERT", f"Temperature exceeded threshold: {temp}°C"
    elif temp < 10:
        return "ALERT", f"Temperature below threshold: {temp}°C"
    elif hum > 90:
        return "ALERT", f"Humidity exceeded threshold: {hum}%"
    elif hum < 20:
        return "ALERT", f"Humidity below threshold: {hum}%"
    return "NORMAL", None


def handler(event, context):
    table = dynamodb.Table(DDB_TABLE)

    records = event.get("records", {})
    messages = []
    for partition_records in records.values():
        for record in partition_records:
            raw = base64.b64decode(record["value"]).decode("utf-8")
            messages.append(json.loads(raw))

    print(f"Processing batch: {len(messages)} messages")

    for data in messages:
        sensor_id = data.get("sensorId", "unknown")
        timestamp = data.get("timestamp", "")
        temperature = data.get("temperature", 0)
        humidity = data.get("humidity", 0)
        location = data.get("location", "")

        status, reason = detect_anomaly(temperature, humidity)

        table.put_item(Item={
            "sensorId": sensor_id,
            "timestamp": timestamp,
            "temperature": str(temperature),
            "humidity": str(humidity),
            "location": location,
            "status": status,
        })

        if status == "ALERT":
            print(f"{sensor_id}: ALERT - {reason}")
            if ALERT_TOPIC_ARN:
                alert_payload = {**data, "status": "ALERT", "alert_reason": reason}
                sns_client.publish(
                    TopicArn=ALERT_TOPIC_ARN,
                    Message=json.dumps(alert_payload),
                )
        else:
            print(f"{sensor_id}: NORMAL - temp={temperature}°C, humidity={humidity}%")

    return {"statusCode": 200, "processed": len(messages)}
