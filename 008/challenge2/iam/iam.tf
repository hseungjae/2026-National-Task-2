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

resource "aws_iam_role_policy_attachment" "lattice_client_admin" {
  role       = aws_iam_role.lattice_client.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "lattice_client" {
  name = "skills-lattice-client-profile"
  role = aws_iam_role.lattice_client.name
}
