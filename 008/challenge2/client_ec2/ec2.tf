locals {
  client_app_b64 = base64encode(file("${path.module}/../배포파일/client_app.py"))
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "skills-lattice-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "local_file" "ec2_key_pem" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.module}/skills-lattice-key.pem"
  file_permission = "0600"
}

resource "aws_instance" "lattice_client" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.client_public_subnet_id
  vpc_security_group_ids      = [aws_security_group.client_ec2.id]
  iam_instance_profile        = var.instance_profile_name
  key_name                    = aws_key_pair.ec2_key.key_name
  associate_public_ip_address = true
  user_data_base64 = base64encode(<<-USERDATA
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x

    yum install -y python3
    mkdir -p /opt/lattice

    printf '%s' '${local.client_app_b64}' | base64 -d > /opt/lattice/client_app.py

    cat > /etc/systemd/system/lattice-client.service <<'SVCEOF'
    [Unit]
    Description=Lattice Client App
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/lattice/client_app.py
    Environment=SERVICE_URL=http://${var.lattice_service_dns}
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable --now lattice-client
    echo "client userdata done"
  USERDATA
  )

  tags = {
    Name = "skills-lattice-client-ec2"
  }
}
