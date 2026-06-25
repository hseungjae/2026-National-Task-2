#!/bin/bash
# Lambda@Edge response (origin-response) 빌드 & 배포 스크립트
# 실행 환경: AWS CloudShell (us-east-1)
# 실행: bash build_response.sh
# 순서: terraform apply 후 실행 → 이 스크립트 실행 → 완료
# request Lambda는 Terraform이 직접 관리 (Pillow 불필요)

set -e

BEONHO="100"   # ★ 본인 수험번호로 변경
BUCKET="gj2026-cdn-bucket-$BEONHO"
REGION="us-east-1"
REPO_DIR="/home/cloudshell-user/lambda_ai"
EDGE_DIR="$REPO_DIR/edge-rotate-cdn/lambda_edge"

# ──────────────────────────────────────────
# 0. 환경 구성
# ──────────────────────────────────────────
echo ">>> [0] 환경 구성..."
sudo dnf install -y git python3.14-pip -q 2>/dev/null || true

if [ -d "$REPO_DIR" ]; then
  echo ">>> 기존 레포 pull..."
  sudo git -C "$REPO_DIR" pull -q
else
  echo ">>> 레포 clone..."
  sudo git clone https://github.com/ljh-081210/lambda_ai "$REPO_DIR" -q
fi

sudo chown -R cloudshell-user:cloudshell-user "$REPO_DIR" 2>/dev/null || true

# ──────────────────────────────────────────
# 1. gj2026-cdn-response (origin-response) - Pillow 번들
# ──────────────────────────────────────────
echo ""
echo ">>> [2] gj2026-cdn-response 배포 (Pillow 번들)..."

cd "$EDGE_DIR/origin_response"

# S3_BUCKET 값 치환 (원본 파일 백업 후 치환)
cp lambda_function.py lambda_function.py.bak
sed -i "s|S3_BUCKET = 'gj2026-cdn-bucket'|S3_BUCKET = '$BUCKET'|g" lambda_function.py

rm -rf package
mkdir -p package

pip3 install Pillow \
  --platform manylinux2014_x86_64 \
  --target ./package \
  --only-binary=:all: \
  --python-version 3.14 \
  -q

# handler.lambda_handler 과 맞추기 위해 handler.py 로 rename
cp lambda_function.py ./package/handler.py
# 원본 복구
mv lambda_function.py.bak lambda_function.py

cd package
zip -r9 /tmp/response.zip . -q
cd ..

aws lambda update-function-code \
  --function-name gj2026-cdn-response \
  --zip-file fileb:///tmp/response.zip \
  --region "$REGION" > /dev/null

aws lambda wait function-updated \
  --function-name gj2026-cdn-response \
  --region "$REGION"

RES_ARN=$(aws lambda publish-version \
  --function-name gj2026-cdn-response \
  --region "$REGION" \
  --query 'FunctionArn' --output text)

echo ">>> response ARN: $RES_ARN"

# viewer-request 최신 버전 ARN 가져오기
REQ_ARN=$(aws lambda list-versions-by-function \
  --function-name gj2026-cdn-request \
  --region "$REGION" \
  --query 'Versions[-1].FunctionArn' --output text)

echo ">>> request ARN: $REQ_ARN"

# ──────────────────────────────────────────
# 2. CloudFront Lambda ARN 업데이트 (viewer-request + origin-response 모두)
# ──────────────────────────────────────────
echo ""
echo ">>> [2] CloudFront Lambda ARN 업데이트..."

DIST_ID=$(aws cloudfront list-distributions \
  --query 'DistributionList.Items[0].Id' --output text)

ETAG=$(aws cloudfront get-distribution-config \
  --id "$DIST_ID" --query 'ETag' --output text)

aws cloudfront get-distribution-config \
  --id "$DIST_ID" \
  --query 'DistributionConfig' \
  --output json > /tmp/cf_config.json

# jq로 viewer-request + origin-response ARN 모두 교체
jq --arg req "$REQ_ARN" --arg res "$RES_ARN" '
  .CacheBehaviors.Items[].LambdaFunctionAssociations.Items[] |=
    if .EventType == "viewer-request" then .LambdaFunctionARN = $req
    elif .EventType == "origin-response" then .LambdaFunctionARN = $res
    else . end
' /tmp/cf_config.json > /tmp/cf_config_updated.json

aws cloudfront update-distribution \
  --id "$DIST_ID" \
  --if-match "$ETAG" \
  --distribution-config "file:///tmp/cf_config_updated.json" > /dev/null

echo ">>> CloudFront 업데이트 완료 (Deployed 까지 수 분 소요)"

# ──────────────────────────────────────────
# 완료
# ──────────────────────────────────────────
echo ""
echo ">>> 완료!"
echo ">>> origin-response ARN: $RES_ARN"
echo ">>> CloudFront 배포 상태 확인:"
echo ">>> aws cloudfront get-distribution --id $DIST_ID --query 'Distribution.Status' --output text"
