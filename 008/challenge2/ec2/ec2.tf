locals {
  client_app_b64  = base64encode(file("${path.module}/../배포파일/client_app.py"))
  service_app_b64 = base64encode(file("${path.module}/../배포파일/service_app.py"))
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

    for i in $(seq 1 36); do
      SERVICE_DNS=$(aws vpclattice list-services --region ap-northeast-1 \
        --query "items[?name=='skills-lattice-order-service'].dnsEntry.domainName" \
        --output text 2>/dev/null)
      [ -n "$SERVICE_DNS" ] && [ "$SERVICE_DNS" != "None" ] && break
      sleep 10
    done

    cat > /etc/systemd/system/lattice-client.service <<'SVCEOF'
    [Unit]
    Description=Lattice Client App
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/lattice/client_app.py
    Environment=SERVICE_URL=http://LATTICE_SERVICE_DNS
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    sed -i "s|LATTICE_SERVICE_DNS|$SERVICE_DNS|" /etc/systemd/system/lattice-client.service

    systemctl daemon-reload
    systemctl enable --now lattice-client
    echo "client userdata done"
  USERDATA
  )

  tags = {
    Name = "skills-lattice-client-ec2"
  }
}

resource "aws_instance" "lattice_service" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.service_private_subnet_id
  vpc_security_group_ids      = [aws_security_group.service_ec2.id]
  associate_public_ip_address = false
  user_data_base64 = base64encode(<<-USERDATA
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x

    yum install -y python3
    mkdir -p /opt/lattice

    printf '%s' '${local.service_app_b64}' | base64 -d > /opt/lattice/service_app.py

    cat > /etc/systemd/system/lattice-service.service <<'EOF'
    [Unit]
    Description=Lattice Service App
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/lattice/service_app.py
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    EOF

    systemctl daemon-reload
    systemctl enable --now lattice-service
    echo "service userdata done"
  USERDATA
  )

  tags = {
    Name = "skills-lattice-service-ec2"
  }
}
