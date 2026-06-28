#!/bin/bash
# [3단계] CloudShell에서 실행 — ovpn 파일 생성
# terraform apply 완료 후 실행
set -e

REGION="ap-southeast-1"
WORK_DIR="$HOME/easy-rsa-wsc"

if [ ! -f "$WORK_DIR/easyrsa3/pki/issued/client.wsc.crt" ]; then
  echo "오류: PKI 파일이 없음. setup-vpn-certs.sh 먼저 실행하세요."
  exit 1
fi

echo "=== Client VPN 엔드포인트 ID 조회 ==="
ENDPOINT_ID=$(aws ec2 describe-client-vpn-endpoints \
  --region "$REGION" \
  --query "ClientVpnEndpoints[?Tags[?Key=='Name'&&Value=='wsc-vpn']].ClientVpnEndpointId" \
  --output text)

if [ -z "$ENDPOINT_ID" ]; then
  echo "오류: wsc-vpn 엔드포인트를 찾을 수 없음. terraform apply 먼저 실행하세요."
  exit 1
fi

echo "엔드포인트: $ENDPOINT_ID"

echo "=== ovpn 설정 파일 다운로드 ==="
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id "$ENDPOINT_ID" \
  --region "$REGION" \
  --output text > "$HOME/wsc-vpn.ovpn"

echo "=== cert/key 삽입 ==="
CLIENT_CERT=$(openssl x509 -in "$WORK_DIR/easyrsa3/pki/issued/client.wsc.crt")
CLIENT_KEY=$(cat "$WORK_DIR/easyrsa3/pki/private/client.wsc.key")

cat >> "$HOME/wsc-vpn.ovpn" << EOF

<cert>
$CLIENT_CERT
</cert>

<key>
$CLIENT_KEY
</key>
EOF

echo ""
echo "======================================"
echo "완료!"
echo "CloudShell Actions > Download file:"
echo "  ~/wsc-vpn.ovpn"
echo "======================================"
