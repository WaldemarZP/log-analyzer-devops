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
# Install critical dependencies first (ignore system conflicts)
pip3 install --break-system-packages prometheus_client requests || true
# Then attempt full requirements (non-critical packages may fail safely)
pip3 install --break-system-packages -r requirements.txt 2>&1 | grep -v "Cannot uninstall" || true

# Step 4.5: Install VictoriaMetrics for long-term metrics storage (Day 18)
echo "💾 Installing VictoriaMetrics for long-term metrics storage..."
if ! systemctl is-active --quiet victoriametrics; then
    VM_VERSION="v1.96.0"
    VM_URL="https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/${VM_VERSION}/victoria-metrics-linux-amd64-${VM_VERSION}.tar.gz"

    # Download and extract
    cd /tmp
    wget -q "$VM_URL" -O vm.tar.gz
    tar -xzf vm.tar.gz

    # Install binary
    sudo mkdir -p /opt/victoriametrics
    sudo mv victoria-metrics-prod /opt/victoriametrics/

    # Create user (ignore if exists)
    sudo useradd --system --no-create-home --shell /bin/false vmuser 2>/dev/null || true
    sudo chown -R vmuser:vmuser /opt/victoriametrics

    # Create data directory
    sudo mkdir -p /var/lib/victoriametrics
    sudo chown -R vmuser:vmuser /var/lib/victoriametrics

    # Create systemd service
    sudo tee /etc/systemd/system/victoriametrics.service > /dev/null << 'EOF'
[Unit]
Description=VictoriaMetrics
After=network.target

[Service]
Type=simple
User=vmuser
ExecStart=/opt/victoriametrics/victoria-metrics-prod -storageDataPath=/var/lib/victoriametrics
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    # Start service
    sudo systemctl daemon-reload
    sudo systemctl enable --now victoriametrics.service
    echo "✅ VictoriaMetrics installed and started on port 8428"
else
    echo "✅ VictoriaMetrics already running"
fi

# Step 5: Configuring Nginx with security hardening
echo "⚙️  Configuring Nginx reverse proxy with rate limiting..."
# Remove old configs
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/conf.d/rate-limit.conf
rm -f /etc/nginx/conf.d/limit-zones.conf
# Install rate limiting zones (MUST be in conf.d for http context)
cp /home/"$SCRIPT_USER"/log-analyzer-devops/security/nginx/rate-limit.conf /etc/nginx/conf.d/rate-limit.conf
# Install main config
cp /home/"$SCRIPT_USER"/log-analyzer-devops/security/nginx/log-analyzer.conf /etc/nginx/sites-enabled/
# Test and restart
nginx -t && systemctl restart nginx

# Step 6: Launching the monitoring stack
echo "🐳 Starting monitoring stack..."
cd /home/"$SCRIPT_USER"/log-analyzer-devops
chown -R "$SCRIPT_USER":"$SCRIPT_USER" /home/"$SCRIPT_USER"/log-analyzer-devops
sudo -u "$SCRIPT_USER" docker-compose -f /home/"$SCRIPT_USER"/log-analyzer-devops/docker-compose.yml up -d

# Step 7: Configure horizontal scaling with systemd template (3 instances)
echo "📈 Configuring horizontal scaling (3 instances via systemd)..."
cp /home/"$SCRIPT_USER"/log-analyzer-devops/systemd/log-analyzer@.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now log-analyzer@1.service
systemctl enable --now log-analyzer@2.service
systemctl enable --now log-analyzer@3.service
echo "✅ All 3 analyzer instances started (ports 8001-8003)"

# Step 8: Apply Nginx load balancing configuration
echo "⚖️  Applying Nginx load balancing configuration..."
cp /home/"$SCRIPT_USER"/log-analyzer-devops/nginx/log-analyzers-upstream.conf /etc/nginx/conf.d/
cp /home/"$SCRIPT_USER"/log-analyzer-devops/security/nginx/log-analyzer.conf /etc/nginx/sites-enabled/
nginx -t && systemctl restart nginx
echo "✅ Load balancing active (round-robin between instances)"

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