# 사용자 입력 값을 저장할 DynamoDB 테이블
# - PK: id
# - 온디맨드(PAY_PER_REQUEST) 용량 모드로 과금 최소화
# - deletion_protection 활성화로 삭제 방지
resource "aws_dynamodb_table" "api_storage" {
  name                        = var.table_name
  billing_mode                = "PAY_PER_REQUEST"
  hash_key                    = "id"
  deletion_protection_enabled = true

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_dynamodb_table_item" "seed_check" {
  table_name = aws_dynamodb_table.api_storage.name
  hash_key   = "id"

  item = jsonencode({
    id   = { S = "lambda-chk-999" }
    name = { S = "Check-Post" }
    team = { S = "DevOps" }
  })
}
