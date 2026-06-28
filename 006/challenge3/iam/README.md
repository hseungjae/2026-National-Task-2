# IAM 모듈 (Challenge 3)

EC2와 Lambda 함수 실행에 필요한 IAM Role·Policy를 생성한다.

---

## 생성 리소스

| 리소스 | 이름 | 설명 |
|--------|------|------|
| `aws_iam_role` | `gj2026-event-ec2-role` | EC2 실행 Role (AdministratorAccess) |
| `aws_iam_instance_profile` | `gj2026-event-ec2-profile` | EC2 Instance Profile |
| `aws_iam_role` | `gj2026-event-recovery-lambda-role` | recovery Lambda 실행 Role |
| `aws_iam_role_policy` | `gj2026-event-recovery-lambda-policy` | SSM SendCommand + CW 읽기 권한 |
| `aws_iam_role` | `gj2026-event-updater-lambda-role` | updater Lambda 실행 Role |
| `aws_iam_role_policy` | `gj2026-event-updater-lambda-policy` | SSM Parameter 읽기·쓰기 권한 |

### recovery Lambda 권한

| Action | 설명 |
|--------|------|
| `ssm:SendCommand`, `ssm:GetCommandInvocation` | EC2에 복구 명령 전송 |
| `ssm:GetParameter` | 파라미터 조회 |
| `cloudwatch:GetMetricStatistics`, `cloudwatch:DescribeAlarms` | 알람 상태 조회 |
| `logs:*` | CloudWatch Logs 기록 |

### updater Lambda 권한

| Action | 설명 |
|--------|------|
| `ssm:SendCommand`, `ssm:GetCommandInvocation` | EC2 명령 전송 |
| `ssm:GetParameter`, `ssm:PutParameter` | 파라미터 읽기·쓰기 |
| `logs:*` | CloudWatch Logs 기록 |

---

## Variables

| 이름 | 필수 | 설명 |
|------|------|------|
| `account_id` | Y | AWS Account ID |

## Outputs

| 이름 | 설명 |
|------|------|
| `ec2_role_name` | EC2 Role 이름 |
| `ec2_profile_name` | EC2 Instance Profile 이름 |
| `recovery_lambda_role_arn` | recovery Lambda Role ARN |
| `updater_lambda_role_arn` | updater Lambda Role ARN |
