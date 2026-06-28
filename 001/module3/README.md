# Module 3 — Workflow (us-east-1)

## 구성 리소스

| 서브모듈 | 생성 리소스 |
|---|---|
| s3 | S3 버킷 `wsc2026-wf-inbound-bucket` (EventBridge 알림 활성화) |
| dynamodb | DynamoDB 테이블 `wsc2026-target-db` |
| iam | Step Functions / Lambda 공용 실행 역할 + 정책 |
| lambda | Lambda 함수 `wsc2026-transform-lambda` (python3.14) |
| stepfunctions | Step Functions 상태 머신 `wsc2026-workflow-sf` |
| eventbridge | EventBridge 규칙 `wsc2026-s3-trigger-rule` (S3 → Step Functions) |

Lambda 코드(`lambda_transform.py`)는 `archive_file` 데이터소스가 자동으로 zip 패키징.

---

## 수동 작업 순서

### 1. Terraform 초기화 및 배포

```bash
cd module3
terraform init
terraform apply
```

완료 후 출력값 확인:

```bash
terraform output
```

### 2. 워크플로우 동작 확인

S3 버킷에 오브젝트를 업로드하면 EventBridge → Step Functions → Lambda → DynamoDB 순으로 처리된다.

```bash
# 테스트 파일 업로드
aws s3 cp <local-file> s3://wsc2026-wf-inbound-bucket/ --region us-east-1

# Step Functions 실행 내역 확인
aws stepfunctions list-executions \
  --state-machine-arn <state_machine_arn> \
  --region us-east-1
```

Step Functions 실행이 `SUCCEEDED` 상태인지 확인한다.  
`ValidationError`가 발생하면 `HandleError(Fail)` 상태로 전환된다.

---

## 의존 관계

```
S3 / DynamoDB → IAM → Lambda → StepFunctions → EventBridge
```

> S3 버킷의 EventBridge 알림이 활성화되어 있어야 트리거가 동작한다 (terraform apply 시 자동 설정됨).
