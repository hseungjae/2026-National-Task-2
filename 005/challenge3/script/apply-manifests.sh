#!/bin/bash
set -e

CLUSTER_NAME="wsc-logging-cluster"
REGION="ap-northeast-1"

# kubectl 설치 (미설치 시)
if ! command -v kubectl &>/dev/null; then
  KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -sLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
fi

aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION

# gp2 StorageClass를 default로 패치
kubectl patch storageclass gp2 -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Loki 서비스를 LoadBalancer로 패치
kubectl patch svc loki -n wsc-logging -p '{
  "spec": {"type": "LoadBalancer"},
  "metadata": {"annotations": {
    "service.beta.kubernetes.io/aws-load-balancer-type": "nlb",
    "service.beta.kubernetes.io/aws-load-balancer-nlb-target-type": "ip",
    "service.beta.kubernetes.io/aws-load-balancer-scheme": "internet-facing"
  }}
}'

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

# Fluent Bit 설치
if ! systemctl list-units --full -all | grep -q fluent-bit; then
  curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
fi

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
