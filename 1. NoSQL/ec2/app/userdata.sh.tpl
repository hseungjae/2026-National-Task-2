#!/bin/bash
dnf install -y python3.13-pip

cat > /home/ec2-user/requirements.txt << 'EOF'
${requirements}
EOF

cat > /home/ec2-user/app.py << 'EOF'
${app_py}
EOF

chown ec2-user:ec2-user /home/ec2-user/app.py /home/ec2-user/requirements.txt
python3.13 -m pip install -r /home/ec2-user/requirements.txt

cat > /etc/systemd/system/flask-app.service << 'EOF'
[Unit]
Description=Flask Reservation App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user
Environment=TABLE_NAME=${table_name}
Environment=AWS_REGION=${aws_region}
Environment=GSI_NAME=${gsi_name}
ExecStart=/usr/bin/python3.13 /home/ec2-user/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app
