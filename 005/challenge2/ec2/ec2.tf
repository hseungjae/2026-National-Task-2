resource "aws_eip" "bastion" {
  domain = "vpc"
}

resource "aws_instance" "bastion" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = var.hub_public_subnet_a_id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = var.bastion_profile_name

  user_data = <<-EOF
    #!/bin/bash
    set -e

    # SSH 패스워드 인증 활성화
    echo "Skill53##" | passwd --stdin ec2-user
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOF

  tags = {
    Name = "wsc-hub-bastion"
  }
}

resource "aws_eip_association" "bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion.id
}

resource "aws_instance" "app_v1" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = var.spoke_private_subnet_a_id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = var.app_profile_name

  user_data = <<EOF
#!/bin/bash
dnf install -y python3-pip
pip3 install flask

cat > /home/ec2-user/app.py << 'PYEOF'
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/version', methods=['GET'])
def get_version():
  try:
    ret = {'version': 'v1'}

    return jsonify(ret), 200
  except Exception as e:
    abort(500)

@app.route('/healthcheck', methods=['GET'])
def get_healthcheck():
  try:
    ret = {'status': 'ok'}

    return jsonify(ret), 200
  except Exception as e:
    abort(500)

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8080)
PYEOF

nohup python3 /home/ec2-user/app.py > /dev/null 2>&1 &
EOF

  tags = {
    Name = "wsc-spoke-app-v1"
  }
}

resource "aws_instance" "app_v2" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  subnet_id              = var.spoke_private_subnet_a_id
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = var.app_profile_name

  user_data = <<EOF
#!/bin/bash
dnf install -y python3-pip
pip3 install flask

cat > /home/ec2-user/app.py << 'PYEOF'
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/version', methods=['GET'])
def get_version():
  try:
    ret = {'version': 'v2'}

    return jsonify(ret), 200
  except Exception as e:
    abort(500)

@app.route('/healthcheck', methods=['GET'])
def get_healthcheck():
  try:
    ret = {'status': 'ok'}

    return jsonify(ret), 200
  except Exception as e:
    abort(500)

if __name__ == "__main__":
  app.run(host='0.0.0.0', port=8080)
PYEOF

nohup python3 /home/ec2-user/app.py > /dev/null 2>&1 &
EOF

  tags = {
    Name = "wsc-spoke-app-v2"
  }
}
