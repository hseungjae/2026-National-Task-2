#!/bin/bash
set -e
exec > >(tee /var/log/user-data.log) 2>&1

dnf update -y
dnf install -y docker
systemctl enable --now docker
sleep 5

docker run -d \
  --name keycloak \
  --restart unless-stopped \
  -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD='${admin_password}' \
  -e KC_HTTP_ENABLED=true \
  -e KC_HOSTNAME_STRICT=false \
  -e KC_PROXY_HEADERS=xforwarded \
  -v keycloak-data:/opt/keycloak/data \
  quay.io/keycloak/keycloak \
  start-dev

# Keycloak 부팅 대기 후 master realm SSL 해제
until docker exec keycloak /opt/keycloak/bin/kcadm.sh config credentials \
  --server http://localhost:8080 --realm master \
  --user admin --password '${admin_password}' 2>/dev/null; do
  sleep 3
done

docker exec keycloak /opt/keycloak/bin/kcadm.sh update realms/master \
  -s sslRequired=NONE

echo "=== Keycloak ready ==="
