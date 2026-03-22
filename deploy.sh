#!/bin/bash
set -e

echo "🚀 Log Analyzer Deployment Script"
echo "=================================="

# Checking superuser privileges
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Script must be run as root (use sudo)"
    exit 1
fi

# User identification (not root)
SCRIPT_USER="${SUDO_USER:-ubuntu}"

# Step 1: Updating packages
echo "📦 Updating package lists..."
apt update -y

# Step 2: Installing dependencies
echo "📥 Installing dependencies..."
apt install -y docker.io docker-compose nginx python3 python3-pip

# Step 3: Configuring permissions for Docker
echo "🔧 Configuring Docker permissions..."
usermod -aG docker "$SCRIPT_USER"

# Step 4: Installing Python dependencies
echo "🐍 Installing Python dependencies..."
apt install -y python3-requests python3-pip
pip3 install --break-system-packages -r requirements.txt || echo "⚠️ Non-critical pip installation warning (safe to ignore)"

# Step 5: Configuring Nginx
echo "⚙️  Configuring Nginx reverse proxy..."
ln -sf /home/"$SCRIPT_USER"/log-analyzer-devops/nginx/log-analyzer.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# Step 6: Launching the monitoring stack
echo "🐳 Starting monitoring stack..."
cd /home/"$SCRIPT_USER"/log-analyzer-devops
sudo -u "$SCRIPT_USER" docker-compose up -d

echo ""
echo "✅ Deployment completed successfully!"
echo ""
echo "🔗 Access services:"
echo "   • Grafana: http://$(hostname -I | awk '{print $1}')"
echo "   • Prometheus: http://$(hostname -I | awk '{print $1}')/prometheus/"
echo ""
echo "💡 Next steps:"
echo "   • Run log analyzer: sudo -u $SCRIPT_USER python3 /home/$SCRIPT_USER/log-analyzer-devops/log_analyzer.py --file /home/$SCRIPT_USER/log-analyzer-devops/sample.log"
echo "   • For 24/7 operation: enable systemd service (see systemd/log-analyzer.service)"
echo ""
echo "⚠️  IMPORTANT: Reboot the VM or run 'newgrp docker' manually to apply Docker group changes"