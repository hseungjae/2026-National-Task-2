resource "keycloak_realm" "aws" {
  realm        = "wsc2026-aws"
  enabled      = true
  ssl_required = "none"

  login_with_email_allowed = true
  registration_allowed     = false
  verify_email             = false
}

resource "keycloak_required_action" "disabled" {
  for_each = toset([
    "VERIFY_PROFILE",
    "VERIFY_EMAIL",
    "UPDATE_PROFILE",
    "UPDATE_PASSWORD",
    "CONFIGURE_TOTP",
    "TERMS_AND_CONDITIONS",
  ])

  realm_id       = keycloak_realm.aws.id
  alias          = each.value
  enabled        = false
  default_action = false
}

# admin-cli의 Direct Access Grants 활성화는 apply 후 AWS CloudShell에서 실행:
#
#   bash scripts/configure-admin-cli.sh
#
# 이 스크립트는 ALB DNS를 자동 조회하고, admin-cli를 활성화하고,
# 로그인 검증까지 한 번에 수행함.
