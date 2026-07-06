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
WORK_DIR="/tmp/gj2026-response-build"

# ──────────────────────────────────────────
# 0. 환경 구성
# ──────────────────────────────────────────
echo ">>> [0] 환경 구성..."
sudo dnf install -y python3.14-pip -q 2>/dev/null || true

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/package"

# ──────────────────────────────────────────
# 1. gj2026-cdn-response (origin-response) - Pillow 번들
# ──────────────────────────────────────────
echo ""
echo ">>> [1] gj2026-cdn-response 배포 (Pillow 번들)..."

cat <<EOF > "$WORK_DIR/package/handler.py"
import base64
import io
import boto3
from botocore.exceptions import ClientError
from PIL import Image

S3_BUCKET = '$BUCKET'
s3 = boto3.client('s3', region_name='us-east-1')


def parse_qs(qs):
    params = {}
    for kv in (qs or '').split('&'):
        if '=' in kv:
            k, v = kv.split('=', 1)
            params[k.strip()] = v.strip()
    return params


def lambda_handler(event, context):
    cf = event['Records'][0]['cf']
    request = cf['request']
    response = cf['response']

    params = parse_qs(request.get('querystring', ''))
    rotate = int(params.get('rotate', '0')) % 360
    image_name = params.get('image', '')
    print(f"[INFO] image={image_name}, rotate={rotate}")

    if rotate == 0:
        return response

    s3_key = f'images/{image_name}.png'
    try:
        obj = s3.get_object(Bucket=S3_BUCKET, Key=s3_key)
        png_bytes = obj['Body'].read()
    except ClientError as e:
        print(f"[ERROR] S3 fetch failed: {e}")
        return response

    img = Image.open(io.BytesIO(png_bytes))
    rotated = img.rotate(-rotate, expand=True)

    buf = io.BytesIO()
    rotated.save(buf, format='PNG')
    rotated_png = buf.getvalue()
    print(f"[INFO] Rotated {rotate}deg ({img.width}x{img.height} -> {rotated.width}x{rotated.height}), size={len(rotated_png)}")

    response['body'] = base64.b64encode(rotated_png).decode()
    response['bodyEncoding'] = 'base64'
    response['headers']['content-type'] = [{'key': 'Content-Type', 'value': 'image/png'}]
    response['headers'].pop('content-length', None)
    return response
EOF

pip3 install Pillow \
  --platform manylinux2014_x86_64 \
  --target "$WORK_DIR/package" \
  --only-binary=:all: \
  --python-version 3.14 \
  -q

cd "$WORK_DIR/package"
zip -r9 /tmp/response.zip . -q
cd - > /dev/null

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
