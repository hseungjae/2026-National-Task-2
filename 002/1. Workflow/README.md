# Module 1 - S3 → Step Functions

## Terraform 배포

```bash
terraform init
terraform apply --auto-approve
```

## 파일 업로드

S3 버킷 `wsc2026-student-score-bucket-{비번호}` 의 `input/` 폴더에 `.csv` 파일 업로드 시 State Machine 자동 실행