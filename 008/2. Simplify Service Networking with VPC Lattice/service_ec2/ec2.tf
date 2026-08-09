locals {
  service_app_b64 = base64encode(file("${path.module}/../배포파일/service_app.py"))
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

    cat > /etc/systemd/system/lattice-service.service <<'SVCEOF'
    [Unit]
    Description=Lattice Service App
    After=network.target

    [Service]
    ExecStart=/usr/bin/python3 /opt/lattice/service_app.py
    Restart=always
    RestartSec=5

    [Install]
    WantedBy=multi-user.target
    SVCEOF

    systemctl daemon-reload
    systemctl enable --now lattice-service
    echo "service userdata done"
  USERDATA
  )

  tags = {
    Name = "skills-lattice-service-ec2"
  }
}
