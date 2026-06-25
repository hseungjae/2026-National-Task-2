#!/bin/bash
# [1단계] CloudShell에서 실행 — PKI 생성 + ACM import
# 이후 terraform apply 실행 필요
set -e

REGION="ap-southeast-1"
WORK_DIR="$HOME/easy-rsa-wsc"

echo "=== Easy-RSA 설치 ==="
rm -rf "$WORK_DIR"
git clone https://github.com/OpenVPN/easy-rsa.git "$WORK_DIR" -q
cd "$WORK_DIR/easyrsa3"

echo "=== PKI 초기화 ==="
./easyrsa --batch init-pki

echo "=== CA 생성 ==="
./easyrsa --batch --req-cn="wsc" build-ca nopass

echo "=== 서버 인증서 생성 (cve.wsc) ==="
./easyrsa --batch build-server-full cve.wsc nopass

echo "=== 클라이언트 인증서 생성 (client.wsc) ==="
./easyrsa --batch build-client-full client.wsc nopass

echo ""
echo "=== ACM 임포트 ==="
aws acm import-certificate \
  --certificate fileb://pki/issued/cve.wsc.crt \
  --private-key fileb://pki/private/cve.wsc.key \
  --certificate-chain fileb://pki/ca.crt \
  --region "$REGION" \
  --query "CertificateArn" \
  --output text

aws acm import-certificate \
  --certificate fileb://pki/issued/client.wsc.crt \
  --private-key fileb://pki/private/client.wsc.key \
  --certificate-chain fileb://pki/ca.crt \
  --region "$REGION" \
  --query "CertificateArn" \
  --output text

echo ""
echo "=== 업로드 확인 ==="
aws acm list-certificates \
  --query "CertificateSummaryList[?DomainName=='cve.wsc' || DomainName=='client.wsc'].{Domain:DomainName,ARN:CertificateArn}" \
  --output table \
  --region "$REGION"

echo ""
echo "======================================"
echo "[1단계 완료] 이제 로컬에서 terraform apply 실행"
echo "그 후 setup-ovpn.sh 실행"
echo "======================================"
