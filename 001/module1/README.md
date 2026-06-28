# Module 1 — REST API (ap-northeast-2)

## 구성 리소스

| 서브모듈 | 생성 리소스 |
|---|---|
| dynamodb | DynamoDB 테이블 (`wsc2026-api-storage`) |
| iam | Lambda 실행 역할 + 정책 |
| lambda | Lambda 함수 `wsc2026-api-handler` (python3.14) |
| apigateway | REST API `wsc2026-rest-api`, 스테이지 `V1` |

Lambda 코드(`lambda_api_handler.py`)는 Terraform 내부의 `archive_file` 데이터소스가 자동으로 zip 패키징하므로 별도 빌드 불필요.

---

## 수동 작업 순서

### 1. Terraform 초기화 및 배포

```bash
cd module1
terraform init
terraform apply
```

완료 후 출력값 확인:

```bash
terraform output
```

| 출력 키 | 용도 |
|---|---|
| `api_endpoint` | 배포된 REST API 호출 URL |

### 2. API 동작 확인 (선택)

`terraform output api_endpoint` 로 얻은 URL로 테스트 요청을 보내 Lambda + DynamoDB 연동을 확인한다.

```bash
curl -X POST https://<api-id>.execute-api.ap-northeast-2.amazonaws.com/V1/<resource> \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'
```

---

## 의존 관계

```
DynamoDB → IAM → Lambda → API Gateway
```
