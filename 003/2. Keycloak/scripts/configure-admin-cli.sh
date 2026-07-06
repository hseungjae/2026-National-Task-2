set -e

REGION="ap-northeast-2"
ALB_NAME="wsc2026-keycloak-alb"
REALM="wsc2026-aws"
ADMIN_PASS="Skill53#!!@#"

# 1) ALB DNS 조회
echo "==> ALB DNS 조회..."
ALB=$(aws elbv2 describe-load-balancers \
  --names "$ALB_NAME" \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region "$REGION")
echo "    ALB: $ALB"

# 2) master admin 로그인 (토큰 획득)
echo "==> master admin 로그인..."
TOKEN=$(curl -s -X POST "http://$ALB/realms/master/protocol/openid-connect/token" \
  --data-urlencode "client_id=admin-cli" \
  --data-urlencode "grant_type=password" \
  --data-urlencode "username=admin" \
  --data-urlencode "password=$ADMIN_PASS" \
  | python3 -c "import sys,json;print(json.load(sys.stdin).get('access_token',''))")

if [ -z "$TOKEN" ]; then
  echo "ERROR: admin 로그인 실패. Keycloak이 완전히 부팅되었는지 확인하세요"
  exit 1
fi

# 3) wsc2026-aws realm의 admin-cli UUID 조회
echo "==> $REALM realm의 admin-cli UUID 조회..."
CLIENT_UUID=$(curl -s -H "Authorization: Bearer $TOKEN" \
  "http://$ALB/admin/realms/$REALM/clients?clientId=admin-cli" \
  | python3 -c "import sys,json;print(json.load(sys.stdin)[0]['id'])")

if [ -z "$CLIENT_UUID" ]; then
  echo "ERROR: admin-cli client를 찾을 수 없습니다."
  echo "  module.keycloak apply가 완료되었는지 확인하세요:"
  echo "    terraform apply -target=module.keycloak -auto-approve"
  exit 1
fi
echo "    UUID: $CLIENT_UUID"

# 4) Direct Access Grants 활성화
echo "==> Direct Access Grants 활성화..."
curl -s -X PUT \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  "http://$ALB/admin/realms/$REALM/clients/$CLIENT_UUID" \
  -d '{"directAccessGrantsEnabled": true, "standardFlowEnabled": false}'

echo ""
echo "=========================================================="
echo "==> admin-cli 활성화 완료"
echo "=========================================================="
echo ""
echo "다음 단계 (로컬 터미널에서):"
echo "    terraform apply -auto-approve"
echo ""
echo "완료 후 SSO URL:"
echo "    http://$ALB/realms/$REALM/protocol/saml/clients/amazon-aws"
