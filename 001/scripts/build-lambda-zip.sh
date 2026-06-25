#!/bin/bash
# CloudShell 또는 로컬(Python/pip/zip 필요)에서 실행
# module2/lambda_db_client.zip 을 생성 — pymysql 포함된 Lambda 배포 패키지
# Terraform apply 전에 먼저 실행해야 함
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULE_DIR="$SCRIPT_DIR/../module2"
BUILD_DIR="/tmp/lambda-db-client-build"
ZIP_PATH="$MODULE_DIR/lambda_db_client.zip"

echo "=== Lambda 배포 패키지 빌드 ==="

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

pip3 install pymysql -t "$BUILD_DIR" -q
cp "$MODULE_DIR/lambda_db_client.py" "$BUILD_DIR/"

cd "$BUILD_DIR"
zip -r "$ZIP_PATH" . -q

echo "완료: $ZIP_PATH ($(du -sh "$ZIP_PATH" | cut -f1))"
rm -rf "$BUILD_DIR"
