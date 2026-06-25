# IAM 모듈 (Challenge 1)

Lambda 및 Lambda@Edge 실행에 필요한 IAM Role과 Policy를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_iam_role` | `gj2026-cdn-lambda-role` | Lambda + Lambda@Edge 공용 실행 Role |
| `aws_iam_role_policy` | `gj2026-cdn-lambda-policy` | S3 읽기 + CloudWatch Logs 쓰기 권한 |

### 권한 목록

| Action | Resource |
|--------|----------|
| `s3:GetObject`, `s3:ListBucket` | CDN 버킷 |
| `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` | `arn:aws:logs:*:*:*` |

> Lambda@Edge를 위해 `edgelambda.amazonaws.com`도 Principal에 포함됨

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `bucket_name` | Y | CDN S3 버킷 이름 |

## Outputs

| 이름 | 설명 |
|------|------|
| `lambda_role_arn` | Lambda 실행 Role ARN |
