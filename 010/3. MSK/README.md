terraform apply를 실행해준다.
wsc-app-ec2에서 아래 명령어를 실행해준다.
```

wget https://archive.apache.org/dist/kafka/3.5.1/kafka_2.13-3.5.1.tgz
tar -xzf kafka_2.13-3.5.1.tgz

cd kafka_2.13-3.5.1/bin
export BS="<9092 부트스트랩 문자열>"
./kafka-topics.sh --create --bootstrap-server $BS --topic order-events --partitions 3 --replication-factor 2
./kafka-topics.sh --create --bootstrap-server $BS --topic order-events-dlq --partitions 1 --replication-factor 2
./kafka-topics.sh --list --bootstrap-server $BS

export AWS_REGION=ap-northeast-3
nohup python3.12 ec2_consumer.py \
  --bootstrap-servers "$BS" \
  --topic order-events \
  --bucket wsc-msk-order-data-102-bucket \
  --batch-size 20 &

python3.12 producer.py \
  --bootstrap-servers "$BS" \
  --topic order-events \
  --count 100 --interval 0.01
```