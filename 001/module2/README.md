# Module 2 — RDS Connection (ap-northeast-1)

## 구성 리소스

| 서브모듈 | 생성 리소스 |
|---|---|
| network | VPC, 프라이빗 서브넷, 보안 그룹, DB Subnet Group |
| secrets | Secrets Manager 시크릿 (DB 자격증명) |
| rds | RDS MySQL 8.4.9 인스턴스 (`wsc2026-rds-instance`) |
| proxy | RDS Proxy (`wsc2026-rds-proxy`) + Secrets Manager host 업데이트 |
| lambda | Lambda 함수 `wsc2026-db-client` (VPC 내, pymysql 포함 zip) |

---

## 수동 작업 순서

### 1. Lambda 배포 패키지 빌드 — **terraform apply 전에 반드시 실행**

`lambda_db_client.py`는 `pymysql` 라이브러리를 필요로 한다.  
CloudShell(Linux 환경) 또는 pip/zip이 설치된 로컬에서 아래 스크립트를 실행해 zip을 생성한다.

```bash
bash ../scripts/build-lambda-zip.sh
```

생성 위치: `module2/lambda_db_client.zip`

> **대안 — Lambda Layer 사용 시**  
> zip에 pymysql을 포함하는 대신 Layer를 사용하려면:
> ```bash
> bash ../scripts/deploy-pymysql-layer.sh
> ```
> 출력된 `LAYER_ARN` 값을 `terraform.tfvars`의 `pymysql_layer_arn` 변수에 입력한다.

### 2. Terraform 초기화 및 배포

```bash
cd module2
terraform init
terraform apply
```

> RDS 인스턴스 생성에 약 5~10분, RDS Proxy 생성에 추가로 약 5분 소요된다.

완료 후 출력값 확인:

```bash
terraform output
```

| 출력 키 | 용도 |
|---|---|
| `rds_endpoint` | RDS 직접 접속 엔드포인트 |
| `rds_proxy_endpoint` | RDS Proxy 엔드포인트 |
| `lambda_function_name` | 배포된 Lambda 함수명 |

### 3. DB 초기화 SQL 실행 — **terraform apply 완료 후**

RDS / RDS Proxy는 퍼블릭 액세스가 차단되어 있다.  
프라이빗 서브넷에 접근 가능한 환경(Bastion EC2, CloudShell with VPC 연결 등)에서 아래 SQL을 실행한다.

```bash
mysql -h <rds_proxy_endpoint> -u admin -p
# 비밀번호: Wsc2026Pass!
```

접속 후 `init.sql` 실행:

```sql
source init.sql
```

또는 한 번에:

```bash
mysql -h <rds_proxy_endpoint> -u admin -pWsc2026Pass! < init.sql
```

`init.sql` 내용: `wsc2026.users` 테이블 생성 + 채점용 시드 데이터(`test_user / viewer`) 삽입.

### 4. Lambda 동작 확인 (선택)

AWS 콘솔 또는 CLI로 `wsc2026-db-client` 함수를 테스트 이벤트로 호출해 RDS Proxy 경유 DB 접속을 확인한다.

```bash
aws lambda invoke \
  --function-name wsc2026-db-client \
  --region ap-northeast-1 \
  --payload '{}' \
  response.json
cat response.json
```

---

## 의존 관계

```
network → secrets → rds → proxy → lambda
                                ↑
                   (Secrets Manager host 업데이트 포함)
```
