#!/bin/bash
# EC2 (wsc2026-sensor-producer) 안에서 실행
set -e

REGION="ap-northeast-1"
S3_BUCKET="wsc2026-sensor-alert-bucket-100"

echo "=== [1/5] MSK Cluster ARN 가져오기 ==="
CLUSTER_ARN=$(aws kafka list-clusters \
  --region $REGION \
  --query "ClusterInfoList[?ClusterName=='wsc2026-msk-cluster'].ClusterArn" \
  --output text)
echo "Cluster ARN: $CLUSTER_ARN"

echo "=== [2/5] Bootstrap Broker 주소 가져오기 ==="
BOOTSTRAP=$(aws kafka get-bootstrap-brokers \
  --cluster-arn $CLUSTER_ARN \
  --region $REGION \
  --query BootstrapBrokerStringSaslIam \
  --output text)
echo "Bootstrap: $BOOTSTRAP"

echo "=== [3/5] Kafka 클라이언트 + MSK IAM Auth 설치 ==="
dnf install -y java-11-amazon-corretto wget 2>/dev/null || true

cd /tmp
if [ ! -f kafka_2.13-3.6.0.tgz ]; then
  wget -q https://archive.apache.org/dist/kafka/3.6.0/kafka_2.13-3.6.0.tgz
fi
tar -xzf kafka_2.13-3.6.0.tgz -C /opt/ 2>/dev/null || true

# MSK IAM Auth JAR
IAM_JAR="/opt/kafka_2.13-3.6.0/libs/aws-msk-iam-auth-2.2.0-all.jar"
if [ ! -f "$IAM_JAR" ]; then
  wget -q -O "$IAM_JAR" \
    https://github.com/aws/aws-msk-iam-auth/releases/download/v2.2.0/aws-msk-iam-auth-2.2.0-all.jar
fi

# IAM 인증 설정 파일
cat > /tmp/client.properties << 'EOF'
security.protocol=SASL_SSL
sasl.mechanism=AWS_MSK_IAM
sasl.jaas.config=software.amazon.msk.auth.iam.IAMLoginModule required;
sasl.client.callback.handler.class=software.amazon.msk.auth.iam.IAMClientCallbackHandler
EOF

KAFKA_BIN="/opt/kafka_2.13-3.6.0/bin"

echo "=== [4/5] MSK 토픽 생성 ==="
# wsc2026-sensor-raw (3 partitions, 2 replication)
$KAFKA_BIN/kafka-topics.sh \
  --bootstrap-server $BOOTSTRAP \
  --command-config /tmp/client.properties \
  --create --if-not-exists \
  --topic wsc2026-sensor-raw \
  --partitions 3 \
  --replication-factor 2
echo "Created: wsc2026-sensor-raw"

# wsc2026-sensor-alert (1 partition, 2 replication)
$KAFKA_BIN/kafka-topics.sh \
  --bootstrap-server $BOOTSTRAP \
  --command-config /tmp/client.properties \
  --create --if-not-exists \
  --topic wsc2026-sensor-alert \
  --partitions 1 \
  --replication-factor 2
echo "Created: wsc2026-sensor-alert"

# 토픽 목록 확인
echo "--- 토픽 목록 ---"
$KAFKA_BIN/kafka-topics.sh \
  --bootstrap-server $BOOTSTRAP \
  --command-config /tmp/client.properties \
  --list

echo "=== [5/5] Producer 앱 설치 + systemd 서비스 등록 ==="
mkdir -p /opt/producer

# S3에서 바이너리 다운로드
aws s3 cp "s3://${S3_BUCKET}/binary/app" /opt/producer/app --region $REGION
chmod +x /opt/producer/app

# systemd 서비스 파일 생성
cat > /etc/systemd/system/producer.service << EOF
[Unit]
Description=MSK Sensor Producer Application
After=network.target

[Service]
User=root
WorkingDirectory=/opt/producer
Environment=BOOTSTRAP_SERVERS=${BOOTSTRAP}
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

echo ""
echo "=== 완료 ==="
echo "Bootstrap: $BOOTSTRAP"
systemctl status producer --no-pager
