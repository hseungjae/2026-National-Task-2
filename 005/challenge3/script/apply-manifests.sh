#!/bin/bash
set -e

CLUSTER_NAME="wsc-logging-cluster"
REGION="ap-northeast-1"
CONTESTANT_NUMBER="${1:-100}"

aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# kubectl 설치 (미설치 시)
if ! command -v kubectl &>/dev/null; then
  KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

# Helm 설치 (미설치 시)
if ! command -v helm &>/dev/null; then
  curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# gp2 StorageClass를 default로 패치 (Loki PVC에 필요)
kubectl patch storageclass gp2 -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# AWS Load Balancer Controller 설치
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
OIDC_URL=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION \
  --query "cluster.identity.oidc.issuer" --output text | sed 's|https://||')
OIDC_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/${OIDC_URL}"

# LBC IAM Policy 생성
curl -sLo /tmp/lbc-policy.json \
  https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy \
  --policy-name AWSLoadBalancerControllerIAMPolicy \
  --policy-document file:///tmp/lbc-policy.json 2>/dev/null || \
aws iam create-policy-version \
  --policy-arn "arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy" \
  --policy-document file:///tmp/lbc-policy.json \
  --set-as-default 2>/dev/null || true

LBC_POLICY_ARN="arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy"

# LBC IAM Role 생성 (IRSA)
cat > /tmp/lbc-trust.json <<TRUST
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Federated": "${OIDC_ARN}"},
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": {
        "${OIDC_URL}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller",
        "${OIDC_URL}:aud": "sts.amazonaws.com"
      }
    }
  }]
}
TRUST

aws iam create-role \
  --role-name AWSLoadBalancerControllerRole \
  --assume-role-policy-document file:///tmp/lbc-trust.json 2>/dev/null || true
aws iam attach-role-policy \
  --role-name AWSLoadBalancerControllerRole \
  --policy-arn $LBC_POLICY_ARN 2>/dev/null || true

LBC_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/AWSLoadBalancerControllerRole"

VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME --region $REGION \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

# LBC helm 설치
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set region=$REGION \
  --set vpcId=$VPC_ID \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$LBC_ROLE_ARN" \
  --wait --timeout 5m

# Grafana helm 레포 추가
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 네임스페이스 생성
kubectl create namespace wsc-logging --dry-run=client -o yaml | kubectl apply -f -

# Grafana 대시보드 ConfigMap 생성
kubectl apply -f - <<'MANIFEST'
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-cm
  namespace: wsc-logging
data:
  grafana-dashboard.json: |
    {
      "__inputs": [{"name": "DS_LOKI", "label": "Loki", "description": "", "type": "datasource", "pluginId": "loki", "pluginName": "Loki"}],
      "__elements": {},
      "__requires": [
        {"type": "datasource", "id": "loki", "name": "Loki", "version": "1.0.0"},
        {"type": "panel", "id": "logs", "name": "Logs", "version": ""},
        {"type": "panel", "id": "timeseries", "name": "Time series", "version": ""}
      ],
      "annotations": {"list": []},
      "editable": true,
      "fiscalYearStartMonth": 0,
      "graphTooltip": 0,
      "id": null,
      "links": [],
      "panels": [
        {
          "datasource": {"type": "loki", "uid": "loki"},
          "gridPos": {"h": 10, "w": 24, "x": 0, "y": 0},
          "id": 1,
          "options": {"dedupStrategy": "none", "enableLogDetails": true, "prettifyLogMessage": false, "showCommonLabels": false, "showLabels": false, "showTime": false, "sortOrder": "Descending", "wrapLogMessage": false},
          "targets": [{"datasource": {"type": "loki", "uid": "loki"}, "editorMode": "code", "expr": "{namespace=\"wsc-app-log\"}", "queryType": "range", "refId": "A"}],
          "title": "Any Log",
          "type": "logs"
        },
        {
          "datasource": {"type": "loki", "uid": "loki"},
          "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"}}, "overrides": []},
          "gridPos": {"h": 8, "w": 8, "x": 0, "y": 10},
          "id": 2,
          "options": {"legend": {"calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true}, "tooltip": {"mode": "single", "sort": "none"}},
          "targets": [{"datasource": {"type": "loki", "uid": "loki"}, "editorMode": "code", "expr": "count_over_time({namespace=\"wsc-app-log\"} |= \"INFO\" [1m])", "queryType": "range", "refId": "A"}],
          "title": "INFO Log Count",
          "type": "timeseries"
        },
        {
          "datasource": {"type": "loki", "uid": "loki"},
          "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"}}, "overrides": []},
          "gridPos": {"h": 8, "w": 8, "x": 8, "y": 10},
          "id": 3,
          "options": {"legend": {"calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true}, "tooltip": {"mode": "single", "sort": "none"}},
          "targets": [{"datasource": {"type": "loki", "uid": "loki"}, "editorMode": "code", "expr": "count_over_time({namespace=\"wsc-app-log\"} |= \"ERROR\" [1m])", "queryType": "range", "refId": "A"}],
          "title": "ERROR Log Count",
          "type": "timeseries"
        },
        {
          "datasource": {"type": "loki", "uid": "loki"},
          "fieldConfig": {"defaults": {"color": {"mode": "palette-classic"}}, "overrides": []},
          "gridPos": {"h": 8, "w": 8, "x": 16, "y": 10},
          "id": 4,
          "options": {"legend": {"calcs": [], "displayMode": "list", "placement": "bottom", "showLegend": true}, "tooltip": {"mode": "single", "sort": "none"}},
          "targets": [{"datasource": {"type": "loki", "uid": "loki"}, "editorMode": "code", "expr": "count_over_time({namespace=\"wsc-app-log\"} |= \"WARNING\" [1m])", "queryType": "range", "refId": "A"}],
          "title": "WARNING Log Count",
          "type": "timeseries"
        }
      ],
      "refresh": "5s",
      "schemaVersion": 39,
      "tags": [],
      "time": {"from": "now-1h", "to": "now"},
      "timepicker": {},
      "timezone": "browser",
      "title": "WSC2026 Container Logs",
      "uid": "wsc2026-container-logs",
      "version": 1
    }
MANIFEST

# Loki 설치
helm upgrade --install loki grafana/loki \
  --namespace wsc-logging \
  --timeout 10m \
  --wait \
  --values - <<'YAML'
deploymentMode: SingleBinary

loki:
  auth_enabled: false
  commonConfig:
    replication_factor: 1
  storage:
    type: filesystem
  schemaConfig:
    configs:
      - from: "2024-01-01"
        store: tsdb
        object_store: filesystem
        schema: v13
        index:
          prefix: loki_index_
          period: 24h

singleBinary:
  replicas: 1
  persistence:
    enabled: true
    size: 10Gi

service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
  port: 3100

write:
  replicas: 0
read:
  replicas: 0
backend:
  replicas: 0

gateway:
  enabled: false

chunksCache:
  enabled: false

resultsCache:
  enabled: false
YAML

# Loki 서비스 LoadBalancer 패치 (chart가 ClusterIP로 생성하는 경우 대비)
kubectl annotate svc loki -n wsc-logging \
  service.beta.kubernetes.io/aws-load-balancer-type=external \
  service.beta.kubernetes.io/aws-load-balancer-nlb-target-type=ip \
  service.beta.kubernetes.io/aws-load-balancer-scheme=internet-facing --overwrite
kubectl patch svc loki -n wsc-logging -p '{"spec":{"type":"LoadBalancer"}}'

# Loki NLB 준비 대기
echo "Waiting for Loki NLB to be ready..."
for i in $(seq 1 30); do
  LOKI_HOST=$(kubectl get svc loki -n wsc-logging -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
  if [ -n "$LOKI_HOST" ]; then
    echo "Loki NLB: $LOKI_HOST"
    break
  fi
  echo "Attempt $i: NLB not ready yet, waiting 15s..."
  sleep 15
done

if [ -z "$LOKI_HOST" ]; then
  echo "ERROR: Loki NLB not available after 7.5 minutes"
  exit 1
fi

# Grafana 설치
helm upgrade --install grafana grafana/grafana \
  --namespace wsc-logging \
  --timeout 10m \
  --wait \
  --values - <<EOF
service:
  type: LoadBalancer
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: external
    service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing

adminUser: "wsc2026-admin-${CONTESTANT_NUMBER}"
adminPassword: "admin${CONTESTANT_NUMBER}!"

datasources:
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Loki
      type: loki
      uid: loki
      url: http://loki:3100
      access: proxy
      isDefault: true
      jsonData:
        maxLines: 1000

dashboardProviders:
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: default
      orgId: 1
      folder: ''
      type: file
      disableDeletion: false
      editable: true
      options:
        path: /var/lib/grafana/dashboards/default

dashboardsConfigMaps:
  default: "grafana-dashboard-cm"
EOF

# Docker 설치 및 실행
if ! command -v docker &>/dev/null; then
  sudo dnf install -y docker
  sudo systemctl enable --now docker
  sudo usermod -aG docker ec2-user
fi

# Flask 앱 컨테이너 실행 (미실행 시)
if ! sudo docker ps --format '{{.Names}}' | grep -q wsc-log-app; then
  sudo mkdir -p /app
  sudo chown ec2-user:ec2-user /app

  cat > /app/requirements.txt << 'EOF'
flask==3.1.3
EOF

  cat > /app/app.py << 'EOF'
from flask import Flask, request, jsonify
import logging
import random
import time

app = Flask(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s %(levelname)s %(message)s')
logger = logging.getLogger(__name__)

USERS = ["alice", "bob", "carol", "dave", "eve"]
ACTIONS = ["login", "logout", "purchase", "view_item", "search"]

@app.route("/")
def index():
    return jsonify({"service": "m3-log-generator", "status": "healthy"})

@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200

@app.route("/generate")
def generate():
    count = int(request.args.get("count", 10))
    logs = []
    for _ in range(count):
        user = random.choice(USERS)
        action = random.choice(ACTIONS)
        level = random.choice(["INFO", "INFO", "INFO", "WARNING", "ERROR"])
        msg = f"user={user} action={action} status={'success' if level == 'INFO' else 'failed'}"
        if level == "INFO":
            logger.info(msg)
        elif level == "WARNING":
            logger.warning(msg)
        else:
            logger.error(msg)
        logs.append({"level": level, "message": msg})
        time.sleep(0.05)
    return jsonify({"generated": count, "logs": logs})

@app.route("/error")
def trigger_error():
    logger.error("manual error triggered by /error endpoint")
    return jsonify({"status": "error logged"}), 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

  cat > /app/Dockerfile << 'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

  sudo docker build -t wsc-log-app /app
  sudo docker run -d \
    --name wsc-log-app \
    --restart always \
    --log-driver json-file \
    -p 5000:5000 \
    wsc-log-app
fi

# docker 로그 읽기 권한 부여
sudo chown -R ec2-user:ec2-user /var/lib/docker/containers

# Fluent Bit 설치
if ! systemctl list-units --full -all | grep -q fluent-bit; then
  curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
fi

# Fluent Bit 설정
sudo mkdir -p /etc/fluent-bit
sudo tee /etc/fluent-bit/fluent-bit.conf << EOF
[SERVICE]
    Flush             1
    Daemon            Off
    Log_Level         info
    Parsers_File      /etc/fluent-bit/parsers.conf

[INPUT]
    Name              tail
    Tag               docker.*
    Path              /var/lib/docker/containers/*/*.log
    Parser            docker
    DB                /var/log/flb_docker.db
    Mem_Buf_Limit     5MB
    Skip_Long_Lines   On
    Refresh_Interval  5

[FILTER]
    Name              record_modifier
    Match             docker.*
    Record            namespace wsc-app-log

[OUTPUT]
    Name              loki
    Match             *
    Host              $LOKI_HOST
    Port              3100
    Labels            namespace=wsc-app-log
    Line_Format       json
    Auto_Kubernetes_Labels off
EOF

sudo tee /etc/fluent-bit/parsers.conf << 'EOF'
[PARSER]
    Name        docker
    Format      json
    Time_Key    time
    Time_Format %Y-%m-%dT%H:%M:%S.%L
    Time_Keep   On
EOF

sudo systemctl enable --now fluent-bit
sudo systemctl restart fluent-bit
sudo systemctl status fluent-bit --no-pager

echo "Done!"
