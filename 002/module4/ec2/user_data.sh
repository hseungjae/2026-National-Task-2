#!/bin/bash
set -e

REGION="ap-northeast-1"
S3_BUCKET="${s3_bucket_name}"

# MSK plaintext bootstrap 주소를 런타임에 직접 조회 (최대 10분 대기)
echo "MSK bootstrap 주소 조회 중..."
for i in $(seq 1 20); do
  CLUSTER_ARN=$(aws kafka list-clusters \
    --cluster-name-filter wsc2026-msk-cluster \
    --query "ClusterInfoList[0].ClusterArn" \
    --output text --region $REGION 2>/dev/null)
  BOOTSTRAP=$(aws kafka get-bootstrap-brokers \
    --cluster-arn "$CLUSTER_ARN" \
    --query "BootstrapBrokerString" \
    --output text --region $REGION 2>/dev/null)
  if [ -n "$BOOTSTRAP" ] && [ "$BOOTSTRAP" != "None" ]; then
    echo "Bootstrap 주소 확인: $BOOTSTRAP"
    break
  fi
  echo "[$i/20] MSK 준비 대기 중... (30초 후 재시도)"
  sleep 30
done

if [ -z "$BOOTSTRAP" ] || [ "$BOOTSTRAP" = "None" ]; then
  echo "ERROR: MSK plaintext bootstrap 주소를 가져오지 못했습니다."
  exit 1
fi

echo "=== [1/4] Java + Kafka 클라이언트 설치 ==="
dnf install -y java-11-amazon-corretto wget

cd /tmp
wget -q https://archive.apache.org/dist/kafka/3.6.0/kafka_2.13-3.6.0.tgz
tar -xzf kafka_2.13-3.6.0.tgz -C /opt/

wget -q -O /opt/kafka_2.13-3.6.0/libs/aws-msk-iam-auth-2.2.0-all.jar \
  https://github.com/aws/aws-msk-iam-auth/releases/download/v2.2.0/aws-msk-iam-auth-2.2.0-all.jar

KAFKA_BIN="/opt/kafka_2.13-3.6.0/bin"

echo "=== [2/4] MSK 토픽 생성 ==="
$KAFKA_BIN/kafka-topics.sh \
  --bootstrap-server $BOOTSTRAP \
  --create --if-not-exists \
  --topic wsc2026-sensor-raw \
  --partitions 3 \
  --replication-factor 2

$KAFKA_BIN/kafka-topics.sh \
  --bootstrap-server $BOOTSTRAP \
  --create --if-not-exists \
  --topic wsc2026-sensor-alert \
  --partitions 1 \
  --replication-factor 2

echo "=== [3/4] Producer 바이너리 S3에서 다운로드 ==="
mkdir -p /opt/producer
aws s3 cp "s3://$${S3_BUCKET}/binary/app" /opt/producer/app --region $REGION
chmod +x /opt/producer/app

echo "=== [4/4] systemd 서비스 등록 ==="
cat > /etc/systemd/system/producer.service << EOF
[Unit]
Description=MSK Sensor Producer Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/producer
Environment=BOOTSTRAP_SERVERS=$${BOOTSTRAP}
Environment=TOPIC_RAW=wsc2026-sensor-raw
ExecStart=/opt/producer/app
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable producer
systemctl start producer

echo "=== 완료 ==="
