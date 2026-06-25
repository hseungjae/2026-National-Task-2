#!/bin/bash
# 로컬에서 실행 - app 바이너리를 S3에 업로드

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET="wsc2026-sensor-alert-bucket-100"
BINARY_PATH="C:/Users/USER/Desktop/26 전국/과제풀이/02/2과제/배포파일/module4/app"

echo "Uploading binary to S3..."
aws s3 cp "$BINARY_PATH" "s3://${BUCKET}/binary/app" --region ap-northeast-1
echo "Done: s3://${BUCKET}/binary/app"
