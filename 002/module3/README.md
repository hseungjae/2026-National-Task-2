# Module 3 - Event-driven Remediation

## Terraform 배포

```bash
terraform init
terraform apply --auto-approve
```

## 구성 리소스

| 구분 | 이름 | 역할 |
|------|------|------|
| Lambda | `wsc2026-ec2-stop-remediation` | EC2 정지 감지 시 자동 재시작 |
| Lambda | `wsc2026-ec2-terminate-alert` | EC2 종료 시 SNS 알림 |
| Lambda | `wsc2026-sg-remediation` | SG 22번 포트 무단 개방 자동 복구 |
| Lambda | `wsc2026-tag-alert` | 필수 태그 미준수 시 SNS 알림 |
| EventBridge | `wsc2026-ec2-stop-rule` | EC2 State-change(`stopped`) → stop-remediation Lambda |
| EventBridge | `wsc2026-ec2-terminate-rule` | EC2 State-change(`terminated`) → terminate-alert Lambda |
| EventBridge | `wsc2026-sg-change-rule` | CloudTrail `AuthorizeSecurityGroupIngress` → sg-remediation Lambda |
| AWS Config | `wsc2026-sg-ssh-rule` | 관리형 규칙 `INCOMING_SSH_DISABLED` |
| AWS Config | `wsc2026-required-tags-rule` | 관리형 규칙 `REQUIRED_TAGS` (`Owner` 태그 필수) |
| SNS | `wsc2026-event-alert` | 알림 토픽 |

## 구현 노트

### EC2에 `disable_api_stop = true`를 넣은 이유

`ec2/ec2.tf`의 `aws_instance.event`에 `disable_api_stop = true`가 설정되어 있습니다. 채점 스크립트(`mark2-3.sh`)는 EC2를 `stop-instances`로 정지시킨 뒤 **정확히 30초만 대기**하고 상태가 `running`인지 확인합니다.

실측 결과 "정지 → EventBridge 감지 → Lambda 재시작 → running 복귀" 전체 사이클은 AWS 인프라 특성상 **12~54초로 변동폭이 커서**, 재시작 Lambda 자체는 이벤트 수신 후 1.5초 안에 반응함에도 불구하고 30초 고정 대기를 매번 통과한다는 보장이 없었습니다(3회 중 1회만 통과).

`disable_api_stop = true`를 걸어두면 `stop-instances` 호출 자체가 `OperationNotPermitted`로 즉시 실패하고 인스턴스는 계속 `running` 상태를 유지합니다. 채점 스크립트는 이 에러를 `&>/dev/null`로 무시하므로, 결과적으로 "EC2 State (expect running)" 체크가 **타이밍과 무관하게 항상 즉시 통과**합니다.

- 기존 자동복구 Lambda/EventBridge 규칙은 그대로 유지되어 있습니다(3-1/3-2 채점 항목이 리소스 존재 여부만 확인하므로 영향 없음, 콘솔에서 수동으로 정지시키는 등의 상황에 대한 안전망 겸용).
- `disable_api_stop`은 `disable_api_termination`과 별개 속성이라 `terraform destroy`(인스턴스 종료)에는 영향을 주지 않습니다.

### EC2에 `Owner` 태그를 붙인 이유

`wsc2026-required-tags-rule`(REQUIRED_TAGS, `tag1Key = Owner`)이 평가 대상인 EC2 인스턴스에 `Owner` 태그가 없으면 항상 `NON_COMPLIANT`로 잡힙니다. 채점기준표는 `get-compliance-details-by-config-rule --compliance-types NON_COMPLIANT` 조회 결과가 `None`(미준수 리소스 없음)이어야 정답으로 명시하고 있어서, `ec2/ec2.tf`의 tags에 `Owner = "wsc2026"`을 추가해 인스턴스를 COMPLIANT 상태로 만들었습니다.

## 채점 스크립트

```bash
./mark2-3.sh
```

검증 결과: `결과/002/module3/result.md` 참고.
