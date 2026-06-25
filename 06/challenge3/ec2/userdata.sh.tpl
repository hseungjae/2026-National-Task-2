#!/bin/bash
set -e
exec > /var/log/userdata.log 2>&1

# Install dependencies
yum update -y --allowerasing
yum install -y python3 python3-pip amazon-cloudwatch-agent

pip3 install fastapi uvicorn

# Write app.py from base64
echo "${app_py_b64}" | base64 -d > /home/ec2-user/app.py
chown ec2-user:ec2-user /home/ec2-user/app.py
chmod 644 /home/ec2-user/app.py

# Create FastAPI systemd service
cat > /etc/systemd/system/gj2026-app.service <<'SVCEOF'
[Unit]
Description=GJ2026 FastAPI Application
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/home/ec2-user
ExecStart=/usr/bin/python3 /home/ec2-user/app.py
Restart=on-failure
RestartSec=5
StandardOutput=append:/var/log/gj2026-app.log
StandardError=append:/var/log/gj2026-app.log

[Install]
WantedBy=multi-user.target
SVCEOF

touch /var/log/gj2026-app.log
chmod 664 /var/log/gj2026-app.log

systemctl daemon-reload
systemctl enable gj2026-app
systemctl start gj2026-app

# Create heartbeat script
cat > /usr/local/bin/app-heartbeat.sh <<'HBEOF'
#!/bin/bash
while true; do
  count=$(pgrep -f '[p]ython3.*app.py' | wc -l)
  if [ "$count" -gt 0 ]; then v=1; else v=0; fi
  aws cloudwatch put-metric-data \
    --namespace CWAgent \
    --metric-name app_process_count \
    --value "$v" \
    --storage-resolution 1 \
    --region ap-northeast-2
  sleep 1
done
HBEOF

chmod +x /usr/local/bin/app-heartbeat.sh

# Create heartbeat systemd service
cat > /etc/systemd/system/app-heartbeat.service <<'HBSVCEOF'
[Unit]
Description=App Heartbeat Metric Publisher
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/app-heartbeat.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
HBSVCEOF

systemctl daemon-reload
systemctl enable app-heartbeat
systemctl start app-heartbeat

# Configure CloudWatch agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/gj2026-app.log",
            "log_group_name": "/gj2026/event/app-logs",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWEOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

echo "EC2 setup complete"
