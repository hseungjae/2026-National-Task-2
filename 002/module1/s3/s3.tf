resource "aws_s3_bucket" "student_score" {
  bucket        = "wsc2026-student-score-bucket-${var.contestant_number}"
  force_destroy = true

  tags = { Name = "wsc2026-student-score-bucket-${var.contestant_number}" }
}

resource "aws_s3_object" "input_keep" {
  bucket  = aws_s3_bucket.student_score.id
  key     = "input/.keep"
  content = ""
}
