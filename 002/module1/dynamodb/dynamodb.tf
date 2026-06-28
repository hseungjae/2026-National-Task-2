resource "aws_dynamodb_table" "student_score" {
  name         = "wsc2026-student-score"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "studentId"
  range_key    = "examDate"

  attribute {
    name = "studentId"
    type = "S"
  }

  attribute {
    name = "examDate"
    type = "S"
  }

  tags = { Name = "wsc2026-student-score" }
}
