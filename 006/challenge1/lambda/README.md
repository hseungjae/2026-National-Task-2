# Lambda 모듈 (Challenge 1)

CDN 이미지 처리를 위한 Lambda 함수 3종을 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_lambda_function` | `gj2026-cdn-rotate` | 이미지 회전 처리 (Function URL 공개) |
| `aws_lambda_function_url` | - | rotate 함수의 퍼블릭 URL |
| `aws_lambda_function` | `gj2026-cdn-request` | CloudFront viewer-request 처리 (Lambda@Edge) |
| `aws_lambda_function` | `gj2026-cdn-response` | CloudFront origin-response 처리 (Lambda@Edge) |

### Lambda 설정

| 함수 | Runtime | Timeout | Memory | Publish |
|------|---------|---------|--------|---------|
| rotate | python3.14 | 30s | 512MB | N |
| request | python3.14 | 5s | 128MB | Y |
| response | python3.14 | 30s | 128MB | Y |

> request / response는 `publish = true` — Lambda@Edge에 사용하기 위해 버전 ARN 필요

---

## 수동 작업

response Lambda 코드 변경 후 배포 시 `ignore_changes = [filename, source_code_hash]` 설정으로  
Terraform이 자동 감지하지 않으므로 수동으로 코드를 업데이트해야 한다.

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `role_arn` | Y | Lambda 실행 Role ARN |
| `bucket_name` | Y | CDN S3 버킷 이름 |

## Outputs

| 이름 | 설명 |
|------|------|
| `rotate_function_url` | rotate Lambda Function URL |
| `request_qualified_arn` | request Lambda 버전 ARN (Lambda@Edge용) |
| `response_qualified_arn` | response Lambda 버전 ARN (Lambda@Edge용) |
