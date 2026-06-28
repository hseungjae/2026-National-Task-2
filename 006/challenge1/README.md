# Challenge 1 - CDN (CloudFront + Lambda@Edge)

S3에 이미지를 저장하고 CloudFront + Lambda@Edge로 이미지 회전·캐시 기능을 제공하는 CDN 구성.

---

## 수동 작업

### 1. Lambda Layer 빌드 (필요 시)

```bash
# Linux/Mac
cd challenge1
bash script/build_layer.sh

# Windows
cd challenge1
powershell -File script/build_layer.ps1
```

### 2. response Lambda 패키지 빌드

```bash
bash script/build_response.sh
```

### 3. Terraform 배포

```bash
cd challenge1
terraform init
terraform apply -auto-approve
```

---

## 모듈 구성

| 모듈 | 경로 | 역할 |
|------|------|------|
| s3 | `./s3` | CDN용 S3 버킷 생성 및 이미지 업로드 |
| iam | `./iam` | Lambda@Edge 실행 Role·Policy 생성 |
| lambda | `./lambda` | rotate / request / response Lambda 생성 |
| cloudfront | `./cloudfront` | CloudFront 배포 및 캐시 정책 생성 |

---

## 배포 파일 위치

| 파일 | 경로 |
|------|------|
| 이미지 | `배포파일/CDN/dog.png` |
| Flink 앱 | `배포파일/Real-time data analytics/app.py` |
| 이벤트 앱 | `배포파일/Cloud event handling/app.py` |
