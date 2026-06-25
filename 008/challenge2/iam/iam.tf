resource "aws_iam_role" "lattice_client" {
  name = "skills-lattice-client-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lattice_client" {
  name = "skills-lattice-client-policy"
  role = aws_iam_role.lattice_client.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["vpc-lattice:ListServices", "vpc-lattice:GetService"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "lattice_client" {
  name = "skills-lattice-client-profile"
  role = aws_iam_role.lattice_client.name
}
