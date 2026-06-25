#!/bin/bash
# CloudShell에서 실행 — pymysql Lambda Layer를 ap-northeast-1에 배포
# 실행 후 출력되는 LAYER_ARN을 module2 terraform.tfvars의 pymysql_layer_arn에 입력
set -e

LAYER_NAME="wsc2026-pymysql-layer"
REGION="ap-northeast-1"
RUNTIME="python3.14"
BUILD_DIR="/tmp/pymysql-layer-build"
ZIP_PATH="/tmp/pymysql-layer.zip"

echo "=== pymysql Layer 빌드 시작 ==="

# 이전 빌드 정리
rm -rf "$BUILD_DIR" "$ZIP_PATH"
mkdir -p "$BUILD_DIR/python"

# pymysql 설치 (Layer 구조: python/ 하위에 설치해야 Lambda가 인식)
pip3 install pymysql -t "$BUILD_DIR/python" -q

# zip 패키징
cd "$BUILD_DIR"
zip -r "$ZIP_PATH" python/ -q
echo "빌드 완료: $ZIP_PATH ($(du -sh "$ZIP_PATH" | cut -f1))"

# Lambda Layer 배포
echo "=== Layer 배포 중... ==="
LAYER_VERSION_ARN=$(aws lambda publish-layer-version \
  --layer-name "$LAYER_NAME" \
  --description "pymysql for wsc2026 db-client Lambda" \
  --zip-file "fileb://$ZIP_PATH" \
  --compatible-runtimes "$RUNTIME" \
  --region "$REGION" \
  --query 'LayerVersionArn' \
  --output text)

echo ""
echo "======================================"
echo "Layer 배포 완료!"
echo "LAYER_ARN: $LAYER_VERSION_ARN"
echo "======================================"
echo ""
echo "아래 값을 module2/terraform.tfvars 에 입력하세요:"
echo "pymysql_layer_arn = \"$LAYER_VERSION_ARN\""

# 정리
rm -rf "$BUILD_DIR" "$ZIP_PATH"
