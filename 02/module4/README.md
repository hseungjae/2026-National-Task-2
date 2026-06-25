# Module 4 - MSK Pipeline

## Terraform 배포 전 필수 작업

### 바이너리 복사 (반드시 먼저 실행)

```powershell
Copy-Item "C:\Users\USER\Desktop\26 전국\과제풀이\02\2과제\배포파일\module4\app" `
  "C:\Users\USER\Desktop\26 전국\terraform\2026-National-Task-2\02\module4\scripts\app"
```

## Terraform 배포

```bash
terraform init -upgrade
terraform apply --auto-approve
```

> MSK 클러스터 생성에 약 **15~20분** 소요

## 자동 실행 항목 (EC2 user_data)

Terraform 완료 후 EC2가 자동으로 아래 작업 수행:
- Kafka 설치
- MSK 토픽 생성 (`wsc2026-sensor-raw` 3파티션, `wsc2026-sensor-alert` 1파티션)
- S3에서 producer 바이너리 다운로드
- `producer.service` systemd 등록 및 시작

### user_data 로그 확인 (EC2 SSM 접속 후)

```bash
sudo cat /var/log/cloud-init-output.log
sudo systemctl status producer
sudo journalctl -u producer -n 30
```

## Lambda Event Source Mapping 확인

배포 후 **3~5분** 대기 후 확인:

```bash
aws lambda list-event-source-mappings \
  --function-name wsc2026-sensor-consumer \
  --region ap-northeast-1 \
  --query "EventSourceMappings[0].LastProcessingResult" --output text
```

## ❗ Connection error 발생 시 - Event Source Mapping 재생성

```bash
MSK_ARN=$(aws kafka list-clusters \
  --cluster-name-filter wsc2026-msk-cluster \
  --query "ClusterInfoList[0].ClusterArn" --output text --region ap-northeast-1)

# sensor-consumer 재생성
UUID=$(aws lambda list-event-source-mappings \
  --function-name wsc2026-sensor-consumer \
  --region ap-northeast-1 \
  --query "EventSourceMappings[0].UUID" --output text)
aws lambda delete-event-source-mapping --uuid $UUID --region ap-northeast-1
sleep 20
aws lambda create-event-source-mapping \
  --event-source-arn $MSK_ARN \
  --function-name wsc2026-sensor-consumer \
  --topics wsc2026-sensor-raw \
  --starting-position LATEST \
  --region ap-northeast-1

# sensor-alert-consumer 재생성
UUID2=$(aws lambda list-event-source-mappings \
  --function-name wsc2026-sensor-alert-consumer \
  --region ap-northeast-1 \
  --query "EventSourceMappings[0].UUID" --output text)
aws lambda delete-event-source-mapping --uuid $UUID2 --region ap-northeast-1
sleep 20
aws lambda create-event-source-mapping \
  --event-source-arn $MSK_ARN \
  --function-name wsc2026-sensor-alert-consumer \
  --topics wsc2026-sensor-alert \
  --starting-position LATEST \
  --region ap-northeast-1
```

재생성 후 2~3분 대기 → `LastProcessingResult` 가 `OK` 로 바뀌면 정상

## 채점 스크립트

```bash
./mark2-4.sh
```
