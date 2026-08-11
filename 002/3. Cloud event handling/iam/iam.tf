resource "aws_iam_role" "event_lambda" {
  name = "wsc2026-event-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = { Name = "wsc2026-event-lambda-role" }
}

resource "aws_iam_role_policy" "event_lambda" {
  name = "wsc2026-event-lambda-policy"
  role = aws_iam_role.event_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeSecurityGroups",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:DescribeInstances",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:AssociateIamInstanceProfile",
          "ec2:ReplaceIamInstanceProfileAssociation",
          "ec2:StopInstances",
          "ec2:StartInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:DescribeInstanceStatus",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["sns:Publish"]
        Resource = var.topic_arn
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetInstanceProfile",
          "iam:ListInstanceProfilesForRole",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}
