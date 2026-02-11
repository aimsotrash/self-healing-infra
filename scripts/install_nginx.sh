#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y
systemctl start nginx
systemctl enable nginx

# Install CloudWatch Agent
yum install amazon-cloudwatch-agent -y

# Create health check script
cat << 'EOF' > /usr/local/bin/nginx_health_check.sh
#!/bin/bash

systemctl is-active --quiet nginx
if [ $? -eq 0 ]; then
  aws cloudwatch put-metric-data \
    --namespace "Custom/Nginx" \
    --metric-name "NginxRunning" \
    --value 1
else
  aws cloudwatch put-metric-data \
    --namespace "Custom/Nginx" \
    --metric-name "NginxRunning" \
    --value 0
fi
EOF

chmod +x /usr/local/bin/nginx_health_check.sh

# Run every minute
(crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/nginx_health_check.sh") | crontab -
