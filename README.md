# Log Analyzer DevOps Project

![Monitoring Stack](https://img.shields.io/badge/stack-Prometheus%20%2B%20Grafana-blue)
![Deployment](https://img.shields.io/badge/deployment-Multipass%20%2B%20Docker-green)

Automated log analysis system with real-time monitoring and alerting via Telegram.

## 🚀 Quick Start (5 minutes)

### Prerequisites
- Ubuntu 22.04/24.04 desktop/laptop
- [Multipass](https://multipass.run) installed (`sudo snap install multipass`)
- Internet connection

### One-command deployment
```bash
# 1. Create and start VM
multipass launch --name log-analyzer-vm --memory 1G --disk 10GB

# 2. SSH into VM
multipass shell log-analyzer-vm

# 3. Inside VM: clone repository and run deployment script
git clone https://github.com/WaldemarZP/log-analyzer-devops.git
cd log-analyzer-devops
sudo ./deploy.sh

# 4. Enable and start continuous log analysis (24/7 operation)
sudo systemctl enable log-analyzer.service
sudo systemctl start log-analyzer.service