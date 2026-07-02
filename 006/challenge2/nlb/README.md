# NLB 모듈 (Challenge 2)

Kafka 외부 클라이언트 접속을 위한 Network Load Balancer를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_lb` | `gj2026-data-nlb` | 인터넷facing NLB |
| `aws_lb_target_group` | `gj2026-kafka-tg` | Kafka 외부 포트 9094 타겟 그룹 |
| `aws_lb_target_group_attachment` | - | Kafka EC2 등록 |
| `aws_lb_listener` | - | NLB 9094 TCP 리스너 |

### Health Check

- 프로토콜: TCP
- 포트: 9094
- 정상 임계값: 3회
- 간격: 30초

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `vpc_id` | Y | VPC ID |
| `subnet_id` | Y | Subnet ID |
| `kafka_instance_id` | Y | Kafka EC2 인스턴스 ID |
| `kafka_private_ip` | Y | Kafka EC2 프라이빗 IP |

## Outputs

| 이름 | 설명 |
|------|------|
| `nlb_dns_name` | NLB DNS 이름 |
