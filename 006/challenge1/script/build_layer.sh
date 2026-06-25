#!/bin/bash
# Pillow Lambda Layer 빌드 & 배포 스크립트
# 실행 환경: AWS CloudShell (us-east-1)
# 실행: bash build_layer.sh

set -e

LAYER_NAME="gj2026-cdn-pillow"
REGION="us-east-1"
RUNTIME="python3.14"
BUILD_DIR="/tmp/pillow_layer"
ZIP_PATH="/tmp/pillow_layer.zip"

echo ">>> [1/3] Pillow 설치 중..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/python"

pip3 install pillow \
  --target "$BUILD_DIR/python" \
  --quiet

echo ">>> [2/3] ZIP 압축 중..."
cd "$BUILD_DIR"
zip -r "$ZIP_PATH" python/ -q

echo ">>> [3/3] Lambda Layer 배포 중..."
LAYER_ARN=$(aws lambda publish-layer-version \
  --layer-name "$LAYER_NAME" \
  --description "Pillow for gj2026 CDN" \
  --zip-file "fileb://$ZIP_PATH" \
  --compatible-runtimes "$RUNTIME" \
  --region "$REGION" \
  --query 'LayerVersionArn' \
  --output text)

echo ""
echo ">>> 완료!"
echo ">>> Layer ARN: $LAYER_ARN"
echo ""
echo ">>> 이제 Windows에서 terraform apply 를 실행하세요."
