# Module 4 - MSK Pipeline

## Terraform 배포

```bash
terraform init -upgrade
terraform apply --auto-approve
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
