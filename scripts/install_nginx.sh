#!/bin/bash
# Amazon Linux 2023 user data, rendered by Terraform's templatefile().
dnf install -y nginx
systemctl start nginx
systemctl enable nginx

# Create health check script
cat << 'EOF' > /usr/local/bin/nginx_health_check.sh
#!/bin/bash

systemctl is-active --quiet nginx
if [ $? -eq 0 ]; then
  aws cloudwatch put-metric-data \
    --region "${region}" \
    --namespace "Custom/Nginx" \
    --metric-name "NginxRunning" \
    --value 1
else
  aws cloudwatch put-metric-data \
    --region "${region}" \
    --namespace "Custom/Nginx" \
    --metric-name "NginxRunning" \
    --value 0
fi
EOF

chmod +x /usr/local/bin/nginx_health_check.sh

# Run every minute. AL2023 ships no cron; a systemd timer replaces it.
# AccuracySec=1s keeps runs at the top of the minute, one per alarm period.
cat << 'EOF' > /etc/systemd/system/nginx-health-check.service
[Unit]
Description=Publish nginx health to CloudWatch

[Service]
Type=oneshot
ExecStart=/usr/local/bin/nginx_health_check.sh
EOF

cat << 'EOF' > /etc/systemd/system/nginx-health-check.timer
[Unit]
Description=Run the nginx health check every minute

[Timer]
OnCalendar=minutely
AccuracySec=1s

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now nginx-health-check.timer
