#!/bin/bash
set -e

echo "🛡️  Starting OS hardening..."

# 1. Enable the UFW firewall
ufw --force enable
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 3000
ufw deny 9090
ufw deny 8000

# 2. Disable any unnecessary services
systemctl stop avahi-daemon 2>/dev/null || true
systemctl disable avahi-daemon 2>/dev/null || true

# 3. Configure SSH for security
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd 2>/dev/null || true

# 4. Enable automatic security updates
apt install -y unattended-upgrades
dpkg-reconfigure -f noninteractive unattended-upgrades

echo "✅ Hardening completed successfully!"