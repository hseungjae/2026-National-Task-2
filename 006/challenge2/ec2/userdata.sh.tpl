#!/bin/bash
set -e
exec > /var/log/userdata.log 2>&1

# Install dependencies
yum install -y java-17-amazon-corretto wget python3 python3-pip
pip3 install kafka-python==2.0.2

# Download Kafka
KAFKA_VERSION="3.7.1"
wget https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz
tar -xzf kafka_2.13-$KAFKA_VERSION.tgz
sudo mv kafka_2.13-$KAFKA_VERSION /opt/kafka
sudo chown -R ec2-user:ec2-user /opt/kafka
rm kafka_2.13-$KAFKA_VERSION.tgz

# Get IPs
EC2_PRIVATE_IP=$(hostname -I | awk '{print $1}')

# Wait for NLB
echo "Waiting for NLB..."
NLB_DNS=""
for i in $(seq 1 30); do
  NLB_DNS=$(aws elbv2 describe-load-balancers \
    --names gj2026-data-nlb \
    --query 'LoadBalancers[0].DNSName' \
    --output text \
    --region ap-southeast-1 2>/dev/null || true)
  if [ -n "$NLB_DNS" ] && [ "$NLB_DNS" != "None" ] && [ "$NLB_DNS" != "null" ]; then
    echo "NLB ready: $NLB_DNS"
    break
  fi
  echo "Attempt $i: NLB not ready, waiting 10s..."
  sleep 10
done

# KRaft configuration
sudo tee /opt/kafka/config/kraft/server.properties > /dev/null << EOF
process.roles=broker,controller
node.id=1
controller.quorum.voters=1@localhost:9093

listeners=PLAINTEXT://0.0.0.0:9092,CONTROLLER://localhost:9093,EXTERNAL://0.0.0.0:9094
advertised.listeners=PLAINTEXT://$EC2_PRIVATE_IP:9092,EXTERNAL://$NLB_DNS:9094
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

# Create data directory and format storage
sudo mkdir -p /var/lib/kafka/data
sudo chown -R ec2-user:ec2-user /var/lib/kafka

CLUSTER_ID=$(/opt/kafka/bin/kafka-storage.sh random-uuid)
/opt/kafka/bin/kafka-storage.sh format \
  -t $CLUSTER_ID \
  -c /opt/kafka/config/kraft/server.properties

# Kafka systemd service
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

# Wait for Kafka
echo "Waiting for Kafka..."
for i in $(seq 1 30); do
  if /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092 > /dev/null 2>&1; then
    echo "Kafka ready"
    break
  fi
  sleep 5
done

# Create topics
/opt/kafka/bin/kafka-topics.sh --create \
  --topic order-logs --partitions 2 --replication-factor 1 \
  --bootstrap-server localhost:9092

for TOPIC in error-stats high-latency anomaly; do
  /opt/kafka/bin/kafka-topics.sh --create \
    --topic $TOPIC --partitions 1 --replication-factor 1 \
    --bootstrap-server localhost:9092
done

echo "Kafka topics created"

# Download app.py from S3
mkdir -p /var/log/app
chown ec2-user:ec2-user /var/log/app
aws s3 cp s3://${scripts_bucket}/app.py /home/ec2-user/app.py --region ap-southeast-1
chown ec2-user:ec2-user /home/ec2-user/app.py

# Delete S3 bucket
aws s3 rb s3://${scripts_bucket} --force --region ap-southeast-1

echo "Setup complete"
