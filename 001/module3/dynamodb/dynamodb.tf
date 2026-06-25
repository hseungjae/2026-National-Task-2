# 정제 완료 데이터를 영구 저장할 DynamoDB 테이블 (PK id, 온디맨드)
resource "aws_dynamodb_table" "target_db" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
