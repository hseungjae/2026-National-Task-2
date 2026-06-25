# Challenge 4 - 수동 작업 가이드

## 1. Terraform Apply

```bash
cd terraform/2026-National-Task-2/05/challenge4
terraform init
terraform apply -auto-approve
```

생성되는 리소스:
- DynamoDB 테이블 (wsc-serverless-users)
- Lambda 함수 (python3.14)
- API Gateway (REST API + API Key + Usage Plan)

---

## 2. 수동 작업 없음

Challenge 4는 Terraform만으로 모든 리소스가 구성됩니다.

---

## 3. API 엔드포인트 확인

```bash
# API Gateway URL 확인
cd terraform/2026-National-Task-2/05/challenge4
terraform output

# API Key 값 확인
aws apigateway get-api-keys --include-values \
  --query "items[?name=='wsc-serverless-api-key'].value" \
  --output text
```

---

## 4. API 테스트

```bash
API_URL="<terraform output api_url>"
API_KEY="<api key value>"

# 4-1: Health Check (API Key 불필요)
curl $API_URL/health

# 4-2: Health Check (API Key 불필요)
curl $API_URL/v1/health

# 4-3: User 등록 (API Key 필요)
curl -X POST $API_URL/v1/user \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "test", "age": 25}'

# 4-4: User 목록 (API Key 필요)
curl $API_URL/v1/users \
  -H "x-api-key: $API_KEY"

# 4-5: User 삭제 (API Key 필요)
curl -X DELETE "$API_URL/v1/user?name=test" \
  -H "x-api-key: $API_KEY"

# 4-6: User 조회 (API Key 필요, name & age 파라미터 필수)
curl "$API_URL/v1/user?name=test&age=25" \
  -H "x-api-key: $API_KEY"
```
