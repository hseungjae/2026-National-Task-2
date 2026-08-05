# Module 4 - MSK Pipeline

## 왜 바이너리를 직접 업로드해야 하나

module2의 EC2 앱(`app.py`)은 파이썬 소스코드라 `user_data.sh` 안에 그대로 박아넣을 수 있어서
terraform apply만으로 끝났습니다. 하지만 module4의 producer는 **컴파일된 바이너리(6MB대)**라
user_data 스크립트 용량 제한(16KB) 안에 넣을 수 없습니다. 그래서 S3에 미리 올려두고 EC2가
부팅하면서 다운로드받는 구조입니다 — 이 업로드가 terraform 밖에서 수동으로 해야 하는 유일한 이유입니다.

## 배포 순서

1. `terraform apply --auto-approve` 실행 (MSK 클러스터 생성에 **15~20분** 소요, 백그라운드로 진행됨)
2. apply가 도는 동안 (MSK가 준비되기 전에) 바이너리를 S3에 업로드:

   ```bash
   ./scripts/upload_binary.sh <비번호>
   ```

   `scripts/app` 바이너리는 이 저장소에 이미 포함되어 있으므로 별도로 복사할 필요 없습니다.
   (배포파일이 새 버전으로 바뀌는 등 바이너리를 교체해야 한다면 아래 "바이너리 교체" 참고)

3. EC2는 MSK 부팅을 최대 10분까지 기다렸다가, 그 다음 위 바이너리를 S3에서 받아
   `producer.service`로 자동 실행합니다. 2번을 그 전에 끝내두면 별도 조치가 필요 없습니다.

   EC2가 자동으로 하는 일: Kafka 설치 → MSK 토픽 생성(`wsc2026-sensor-raw` 3파티션,
   `wsc2026-sensor-alert` 1파티션) → S3에서 producer 바이너리 다운로드 →
   `producer.service` systemd 등록 및 시작

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

## 바이너리 교체

문제지 배포파일이 새 버전으로 바뀌는 등 `scripts/app`을 교체해야 할 때만 필요합니다.
새 `module4/app` 바이너리를 받아 이 저장소의 `scripts/app`에 덮어쓰면 됩니다.

```powershell
Copy-Item "<새 배포파일 경로>\module4\app" ".\scripts\app" -Force
```

## 채점 스크립트

```bash
./mark2-4.sh
```
