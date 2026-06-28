#!/bin/bash
# Kafka 설치 스크립트 (EC2에서 직접 실행)
# 실행: bash setup_kafka.sh
set -e

KAFKA_VERSION="3.7.1"
REGION="ap-southeast-1"
NLB_NAME="gj2026-kafka-nlb"

echo ">>> [1] Java 및 wget 설치..."
sudo yum install -y java-17-amazon-corretto wget

echo ">>> [2] Kafka 다운로드..."
wget https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz
tar -xzf kafka_2.13-$KAFKA_VERSION.tgz
sudo mv kafka_2.13-$KAFKA_VERSION /opt/kafka
rm kafka_2.13-$KAFKA_VERSION.tgz

echo ">>> [3] NLB DNS 조회..."
EC2_PRIVATE_IP=$(hostname -I | awk '{print $1}')
NLB_DNS=$(aws elbv2 describe-load-balancers \
  --names $NLB_NAME \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region $REGION)
echo ">>> NLB DNS: $NLB_DNS"
echo ">>> Private IP: $EC2_PRIVATE_IP"

echo ">>> [4] KRaft 설정..."
sudo tee /opt/kafka/config/kraft/server.properties > /dev/null << EOF
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093

listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://localhost:9093,EXTERNAL://0.0.0.0:9094
advertised.listeners=PLAINTEXT://${EC2_PRIVATE_IP}:9092,EXTERNAL://${NLB_DNS}:9094
listener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,EXTERNAL:PLAINTEXT
controller.listener.names=CONTROLLER
inter.broker.listener.name=PLAINTEXT

log.dirs=/var/lib/kafka/data
num.partitions=1
log.retention.hours=24
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1
EOF

echo ">>> [5] 데이터 디렉토리 생성 및 KRaft 초기화..."
sudo mkdir -p /var/lib/kafka/data
sudo chown -R ec2-user:ec2-user /var/lib/kafka

CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
/opt/kafka/bin/kafka-storage.sh format \
  -t $CLUSTER_ID \
  -c /opt/kafka/config/kraft/server.properties

echo ">>> [6] systemd 서비스 등록..."
sudo tee /etc/systemd/system/kafka.service > /dev/null << 'SERVICE'
[Unit]
Description=Apache Kafka
After=network.target

[Service]
User=ec2-user
ExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/kraft/server.properties
ExecStop=/opt/kafka/bin/kafka-server-stop.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload
sudo systemctl enable --now kafka

echo ">>> [7] Kafka 기동 대기..."
for i in $(seq 1 30); do
  if /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    echo ">>> Kafka ready"
    break
  fi
  echo ">>> Attempt $i: waiting..."
  sleep 5
done

echo ">>> [8] 토픽 생성..."
/opt/kafka/bin/kafka-topics.sh --create \
  --topic order-logs --partitions 2 --replication-factor 1 \
  --bootstrap-server localhost:9092

for TOPIC in error-stats high-latency anomaly; do
  /opt/kafka/bin/kafka-topics.sh --create \
    --topic $TOPIC --partitions 1 --replication-factor 1 \
    --bootstrap-server localhost:9092
done

echo ""
echo ">>> 완료! 토픽 목록:"
/opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092
