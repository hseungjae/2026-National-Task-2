# S3 모듈 (Challenge 1)

CDN 이미지 원본을 저장하는 S3 버킷을 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_s3_bucket` | `gj2026-cdn-bucket-<beonho>` | CDN 원본 버킷 (public access 차단) |
| `aws_s3_object` | `images/dog.png` | 이미지 파일 업로드 |

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `beonho` | Y | 수험번호 (버킷 이름 suffix) |
| `account_id` | Y | AWS Account ID |

## Outputs

| 이름 | 설명 |
|------|------|
| `bucket_name` | S3 버킷 이름 |
