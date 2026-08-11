#!/bin/bash
# 로컬에서 실행 - app 바이너리를 S3에 업로드
# 사용법: ./upload_binary.sh <비번호>

set -e

NUM="$1"
if [ -z "$NUM" ]; then
  echo "사용법: $0 <비번호>"
  exit 1
fi

BUCKET="wsc2026-sensor-alert-bucket-${NUM}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BINARY_PATH="${SCRIPT_DIR}/app"

if [ ! -f "$BINARY_PATH" ]; then
  echo "ERROR: $BINARY_PATH 에 바이너리가 없습니다. 문제지 배포파일의 module4/app을 여기로 복사하세요."
  exit 1
fi

echo "Uploading $BINARY_PATH to s3://${BUCKET}/binary/app ..."
aws s3 cp "$BINARY_PATH" "s3://${BUCKET}/binary/app" --region ap-northeast-1
echo "Done: s3://${BUCKET}/binary/app"
