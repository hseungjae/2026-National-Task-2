# Module 4 — VPN (ap-southeast-1)

## 구성 리소스

| 서브모듈 / 리소스 | 생성 리소스 |
|---|---|
| network | VPC, 서브넷 (`vpn-sn-b`), 라우트 테이블 |
| tls_private_key | RSA 2048 키페어 (Terraform 상태에 저장) |
| local_file | `ec2/wsc2026-vpn.pem` (EC2 SSH 접속 키) |
| ec2 | EC2 인스턴스 `vpn-ec2` (al2023, t3.micro, 퍼블릭 IP 없음) |
| vpn | Client VPN 엔드포인트 `wsc-vpn` (UDP 1194, 인증서 인증) |

> **사전 조건**: ACM에 서버(`cve.wsc`) 및 클라이언트(`client.wsc`) 인증서가 import되어 있어야 한다.  
> `data.tf`가 ACM에서 두 인증서를 조회하므로, 인증서가 없으면 `terraform apply`가 실패한다.

---

## 수동 작업 순서

### 1단계 — VPN 인증서 생성 및 ACM import (CloudShell)

**terraform apply 전에 반드시 실행**

```bash
bash ../scripts/setup-vpn-certs.sh
```

스크립트 동작:
1. Easy-RSA 클론 및 PKI 초기화
2. CA 생성
3. 서버 인증서 `cve.wsc` 생성
4. 클라이언트 인증서 `client.wsc` 생성
5. 두 인증서를 `ap-southeast-1` ACM에 import

완료 후 ACM 콘솔에서 `cve.wsc`, `client.wsc` 두 인증서가 `ISSUED` 상태인지 확인한다.

### 2단계 — Terraform 초기화 및 배포

```bash
cd module4
terraform init
terraform apply
```

완료 후 출력값 확인:

```bash
terraform output
```

| 출력 키 | 용도 |
|---|---|
| `vpn_endpoint_id` | Client VPN 엔드포인트 ID |
| `ec2_instance_id` | vpn-ec2 인스턴스 ID |

- EC2 SSH 접속용 PEM 키: `ec2/wsc2026-vpn.pem` (terraform apply 시 자동 생성)

### 3단계 — ovpn 파일 생성 (CloudShell)

**terraform apply 완료 후 실행**

```bash
bash ../scripts/setup-ovpn.sh
```

스크립트 동작:
1. Client VPN 엔드포인트 ID 조회 (`wsc-vpn` 태그 기준)
2. AWS CLI로 `.ovpn` 설정 파일 다운로드
3. 클라이언트 인증서/키를 파일 내에 삽입

완료 후 CloudShell에서 파일 다운로드:
- **CloudShell Actions → Download file → `~/wsc-vpn.ovpn`**

### 4단계 — VPN 클라이언트 연결

다운로드한 `wsc-vpn.ovpn` 파일을 OpenVPN 클라이언트에 import하여 연결한다.

VPN 연결 성공 후 EC2에 SSH 접속:

```bash
ssh -i ec2/wsc2026-vpn.pem ec2-user@<vpn-ec2-private-ip>
```

> EC2는 퍼블릭 IP가 없으므로 VPN 연결 후에만 접근 가능하다.

---

## 의존 관계

```
[1단계] setup-vpn-certs.sh (ACM import)
         ↓
[2단계] terraform apply  →  network → ec2 / vpn
         ↓
[3단계] setup-ovpn.sh (ovpn 파일 생성)
         ↓
[4단계] OpenVPN 연결 → EC2 SSH 접속
```
