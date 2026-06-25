# CloudFront 모듈 (Challenge 1)

Lambda@Edge와 연동된 CloudFront 배포를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_cloudfront_distribution` | `gj2026-cdn` | CloudFront 배포 |
| `aws_cloudfront_cache_policy` | `gj2026-cdn-images-policy` | 이미지 경로 캐시 정책 (TTL 86400s) |
| `aws_cloudfront_origin_request_policy` | `gj2026-cdn-origin-request-policy` | 쿼리스트링 포워딩 정책 |

### 캐시 동작

| 경로 | 캐시 정책 | Lambda@Edge |
|------|-----------|-------------|
| `/*` (기본) | 관리형 CachingDisabled | 없음 |
| `/images` | `gj2026-cdn-images-policy` | viewer-request: request, origin-response: response |

- 쿼리스트링 `image`, `rotate` 캐시 키 포함 및 오리진 포워딩
- 오리진: rotate Lambda Function URL (HTTPS only)

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `lambda_url` | Y | rotate Lambda Function URL |
| `request_lambda_arn` | Y | request Lambda 버전 ARN |
| `response_lambda_arn` | Y | response Lambda 버전 ARN |

## Outputs

| 이름 | 설명 |
|------|------|
| `cloudfront_domain` | CloudFront 배포 도메인 |
