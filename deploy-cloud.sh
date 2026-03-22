#!/bin/bash
set -e

echo "🚀 Starting cloud deployment..."

# Wait for apt to finish background operations
echo "⏳ Waiting for apt to finish background operations..."
while systemctl is-active --quiet apt-daily.service apt-daily-upgrade.service 2>/dev/null; do
  sleep 5
done
echo "✅ Apt background operations completed"

# Install system packages
echo "📦 Installing system packages..."
apt-get update
apt-get install -y docker.io docker-compose-plugin nginx python3 python3-pip git curl

# Clone repository
echo "📥 Cloning repository..."
git clone https://github.com/WaldemarZP/log-analyzer-devops.git /home/ubuntu/log-analyzer-devops

# Install Python dependencies
echo "🐍 Installing Python dependencies..."
cd /home/ubuntu/log-analyzer-devops
pip3 install -r requirements.txt

# Run deployment script
echo "⚙️ Running deployment script..."
chmod +x deploy.sh
./deploy.sh

# Enable log analyzer service
echo "🔁 Enabling log analyzer service..."
cp systemd/log-analyzer.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable log-analyzer.service
systemctl start log-analyzer.service

# Restart Nginx
echo "🌐 Restarting Nginx..."
systemctl restart nginx

echo "✅ Deployment completed successfully!"
echo "   Grafana: http://localhost"
echo "   Prometheus: http://localhost/prometheus"
echo "   Metrics: http://localhost:8000/metrics"