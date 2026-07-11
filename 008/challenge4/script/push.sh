#!/bin/bash
set -e

REGION="ap-northeast-2"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_URL="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/skills-sqs-ecr"

cat > worker.py <<'EOF'
import os
import signal
import time
import boto3

running = True

def stop(_signum, _frame):
    global running
    running = False

signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)

region = os.environ.get("AWS_REGION", "ap-northeast-2")
queue_url = os.environ["SQS_QUEUE_URL"]
processing_seconds = int(os.environ.get("PROCESSING_SECONDS", "20"))

sqs = boto3.client("sqs", region_name=region)

while running:
    response = sqs.receive_message(
        QueueUrl=queue_url,
        MaxNumberOfMessages=1,
        WaitTimeSeconds=10,
        VisibilityTimeout=max(processing_seconds + 30, 60),
    )
    messages = response.get("Messages", [])
    if not messages:
        time.sleep(1)
        continue

    for message in messages:
        print(f"received message_id={message.get('MessageId')}", flush=True)
        time.sleep(processing_seconds)
        sqs.delete_message(
            QueueUrl=queue_url,
            ReceiptHandle=message["ReceiptHandle"],
        )
        print(f"deleted message_id={message.get('MessageId')}", flush=True)
EOF

cat > Dockerfile <<'EOF'
FROM python:3.12-slim

WORKDIR /app

RUN pip install boto3

COPY worker.py .

CMD ["python", "worker.py"]
EOF

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"

docker build -t skills-sqs-ecr .

docker tag skills-sqs-ecr:latest "$ECR_REPO_URL:latest"

docker push "$ECR_REPO_URL:latest"

echo "Done: $ECR_REPO_URL:latest"
