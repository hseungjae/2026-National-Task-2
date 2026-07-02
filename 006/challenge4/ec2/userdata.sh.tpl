#!/bin/bash
exec > /var/log/userdata.log 2>&1

# Step 0: 환경 변수 설정
export KEYCLOAK_DOMAIN="${public_ip}.nip.io"
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_DEFAULT_REGION="eu-central-1"
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD="${keycloak_admin_password}"

# Step 1-1: Java 설치
dnf install -y java-17-amazon-corretto wget

# Step 1-2: Keycloak 다운로드 및 설치
KEYCLOAK_VERSION="24.0.4"
wget https://github.com/keycloak/keycloak/releases/download/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz
tar -xzf keycloak-$KEYCLOAK_VERSION.tar.gz -C /opt/
mv /opt/keycloak-$KEYCLOAK_VERSION /opt/keycloak
useradd -r -s /sbin/nologin keycloak 2>/dev/null || true
chown -R keycloak:keycloak /opt/keycloak

# Step 1-3: Let's Encrypt 인증서 발급
yum install -y certbot --allowerasing

# EIP 연결 대기 (certbot이 도메인 검증을 위해 필요)
for i in $(seq 1 36); do
  CURRENT_IP=$(curl -sf --max-time 5 http://checkip.amazonaws.com 2>/dev/null || echo "")
  if [ "$CURRENT_IP" = "${public_ip}" ]; then break; fi
  sleep 10
done

certbot certonly --standalone \
  -d $KEYCLOAK_DOMAIN \
  --email gsmaws01@gsm.hs.kr \
  --agree-tos \
  --non-interactive || { echo "certbot FAILED"; exit 1; }

# Step 1-4: Keycloak 시작
nohup /opt/keycloak/bin/kc.sh start-dev \
  --https-certificate-file=/etc/letsencrypt/live/$KEYCLOAK_DOMAIN/fullchain.pem \
  --https-certificate-key-file=/etc/letsencrypt/live/$KEYCLOAK_DOMAIN/privkey.pem \
  --hostname=$KEYCLOAK_DOMAIN \
  --hostname-strict=false \
  --https-port=443 > /tmp/keycloak.log 2>&1 &

# Keycloak 시작 대기 (최대 5분)
for i in $(seq 1 60); do
  if curl -sf --max-time 5 http://localhost:8080/realms/master/.well-known/openid-configuration > /dev/null 2>&1; then
    echo "Keycloak is up"
    break
  fi
  sleep 5
done

curl -sk https://$KEYCLOAK_DOMAIN/realms/master/.well-known/openid-configuration \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['issuer'])"

# Step 2: Realm / Client Scope / Client / Group / User 설정 (kcadm)
KCADM=/opt/keycloak/bin/kcadm.sh
$KCADM config credentials --server http://localhost:8080 --realm master \
  --user admin --password "$KEYCLOAK_ADMIN_PASSWORD"

$KCADM create realms -s realm=team -s enabled=true 2>/dev/null || true

SCOPE_ID=$($KCADM create client-scopes -r team \
  -s name=gj2026-keycloak-claims -s protocol=openid-connect \
  -s includeInTokenScope=true -i 2>/dev/null) || \
  SCOPE_ID=$($KCADM get client-scopes -r team \
    | python3 -c "import sys,json; [print(s['id']) for s in json.load(sys.stdin) if s['name']=='gj2026-keycloak-claims']")

$KCADM create "client-scopes/$SCOPE_ID/protocol-mappers/models" -r team \
  -s name=team -s protocol=openid-connect \
  -s protocolMapper=oidc-usermodel-attribute-mapper \
  -s 'config={"user.attribute":"team","multivalued":"true","id.token.claim":"true","access.token.claim":"true","claim.name":"team","userinfo.token.claim":"true","jsonType.label":"String"}' \
  2>/dev/null || true

$KCADM create "client-scopes/$SCOPE_ID/protocol-mappers/models" -r team \
  -s name=group -s protocol=openid-connect \
  -s protocolMapper=oidc-group-membership-mapper \
  -s 'config={"full.path":"false","id.token.claim":"true","access.token.claim":"true","claim.name":"group","userinfo.token.claim":"true"}' \
  2>/dev/null || true

$KCADM create "client-scopes/$SCOPE_ID/protocol-mappers/models" -r team \
  -s name=role -s protocol=openid-connect \
  -s protocolMapper=oidc-usermodel-realm-role-mapper \
  -s 'config={"multivalued":"true","id.token.claim":"true","access.token.claim":"true","claim.name":"role","userinfo.token.claim":"true","jsonType.label":"String"}' \
  2>/dev/null || true

$KCADM create clients -r team -s clientId=gj2026-keycloak-dev \
  -s enabled=true -s protocol=openid-connect -s publicClient=true \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=true \
  -s "defaultClientScopes=[\"gj2026-keycloak-claims\",\"openid\",\"profile\"]" \
  2>/dev/null || true

$KCADM create clients -r team -s clientId=gj2026-keycloak-sec \
  -s enabled=true -s protocol=openid-connect -s publicClient=true \
  -s standardFlowEnabled=false -s directAccessGrantsEnabled=true \
  -s "defaultClientScopes=[\"gj2026-keycloak-claims\",\"openid\",\"profile\"]" \
  2>/dev/null || true

$KCADM create groups -r team -s name=dev-team 2>/dev/null || true
$KCADM create groups -r team -s name=sec-team 2>/dev/null || true

# Step 2-5: 사용자 생성 (API)
ADMIN_TOKEN=$(curl -sk -X POST \
  "https://$KEYCLOAK_DOMAIN/realms/master/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=admin-cli" \
  -d "username=admin" \
  -d "password=$KEYCLOAK_ADMIN_PASSWORD" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

curl -sk -X POST "https://$KEYCLOAK_DOMAIN/admin/realms/team/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"dev-user","firstName":"dev","lastName":"user01","email":"dev-user@team.local","emailVerified":true,"enabled":true,"attributes":{"team":["dev-team"]}}'

curl -sk -X POST "https://$KEYCLOAK_DOMAIN/admin/realms/team/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"sec-user","firstName":"sec","lastName":"user01","email":"sec-user@team.local","emailVerified":true,"enabled":true,"attributes":{"team":["sec-team"]}}'

DEV_USER_ID=$(curl -sk "https://$KEYCLOAK_DOMAIN/admin/realms/team/users?username=dev-user" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

curl -sk -X PUT "https://$KEYCLOAK_DOMAIN/admin/realms/team/users/$DEV_USER_ID/reset-password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"type":"password","value":"dev123!","temporary":false}'

SEC_USER_ID=$(curl -sk "https://$KEYCLOAK_DOMAIN/admin/realms/team/users?username=sec-user" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)[0]['id'])")

curl -sk -X PUT "https://$KEYCLOAK_DOMAIN/admin/realms/team/users/$SEC_USER_ID/reset-password" \
  -H "Authorization: Bearer $ADMIN_TOKEN" -H "Content-Type: application/json" \
  -d '{"type":"password","value":"sec123!","temporary":false}'

DEV_GROUP_ID=$($KCADM get groups -r team \
  | python3 -c "import sys,json; [print(g['id']) for g in json.load(sys.stdin) if g['name']=='dev-team']")
SEC_GROUP_ID=$($KCADM get groups -r team \
  | python3 -c "import sys,json; [print(g['id']) for g in json.load(sys.stdin) if g['name']=='sec-team']")

curl -sk -X PUT "https://$KEYCLOAK_DOMAIN/admin/realms/team/users/$DEV_USER_ID/groups/$DEV_GROUP_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"
curl -sk -X PUT "https://$KEYCLOAK_DOMAIN/admin/realms/team/users/$SEC_USER_ID/groups/$SEC_GROUP_ID" \
  -H "Authorization: Bearer $ADMIN_TOKEN"

# Step 5: credential_process 스크립트 작성 (Notion 그대로)
mkdir -p /home/ec2-user/.aws
cat > /home/ec2-user/.aws/gj2026-keycloak-creds.sh << 'EOF'
#!/bin/bash
TEAM="$1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

EC2_PUBLIC_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gj2026-keycloak-ec2" \
            "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].PublicIpAddress" \
  --output text)

KEYCLOAK_DOMAIN="$${EC2_PUBLIC_IP}.nip.io"
KEYCLOAK_URL="https://$KEYCLOAK_DOMAIN"
REALM="team"

case "$TEAM" in
  dev)
    CLIENT_ID="gj2026-keycloak-dev"
    USERNAME="$${2:-dev-user}"
    PASSWORD="dev123!"
    ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/gj2026-keycloak-dev-role"
    ;;
  sec)
    CLIENT_ID="gj2026-keycloak-sec"
    USERNAME="$${2:-sec-user}"
    PASSWORD="sec123!"
    ROLE_ARN="arn:aws:iam::$ACCOUNT_ID:role/gj2026-keycloak-sec-role"
    ;;
  *)
    echo "Usage: $0 <dev|sec>" >&2
    exit 1
    ;;
esac

TOKEN_RESPONSE=$(curl -sk -X POST \
  "$KEYCLOAK_URL/realms/$REALM/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=$CLIENT_ID" \
  -d "username=$USERNAME" \
  -d "password=$PASSWORD" \
  -d "scope=openid")

ID_TOKEN=$(echo $TOKEN_RESPONSE | python3 -c \
  "import sys,json; print(json.load(sys.stdin)['id_token'])")

CREDS=$(aws sts assume-role-with-web-identity \
  --role-arn "$ROLE_ARN" \
  --role-session-name "keycloak-session" \
  --web-identity-token "$ID_TOKEN" \
  --output json)

echo $CREDS | python3 -c "
import sys,json
d=json.load(sys.stdin)['Credentials']
print(json.dumps({
  'Version': 1,
  'AccessKeyId': d['AccessKeyId'],
  'SecretAccessKey': d['SecretAccessKey'],
  'SessionToken': d['SessionToken'],
  'Expiration': d['Expiration']
}))"
EOF

chmod +x /home/ec2-user/.aws/gj2026-keycloak-creds.sh
chown -R ec2-user:ec2-user /home/ec2-user/.aws

# Step 6: AWS CLI 프로파일 설정
cat >> /home/ec2-user/.aws/config << 'EOF'

[profile gj2026-keycloak-dev]
credential_process = /home/ec2-user/.aws/gj2026-keycloak-creds.sh dev
region = eu-central-1

[profile gj2026-keycloak-sec]
credential_process = /home/ec2-user/.aws/gj2026-keycloak-creds.sh sec
region = eu-central-1
EOF

chown -R ec2-user:ec2-user /home/ec2-user/.aws

echo "Setup complete. Keycloak URL: https://$KEYCLOAK_DOMAIN"
