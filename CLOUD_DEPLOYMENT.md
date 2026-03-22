# Cloud Deployment Guide: Log Analyzer Stack

## 🎯 Overview
This guide describes how to deploy the Log Analyzer monitoring stack to cloud providers (Google Cloud, AWS, Azure) or locally via Multipass.

## ☁️ Option 1: Local Deployment (Recommended for Testing)

### Prerequisites
- Ubuntu/Debian laptop/desktop
- [Multipass](https://multipass.run) installed (`sudo snap install multipass`)

### Deployment Steps
```bash
# Launch VM with cloud-init configuration
multipass launch ubuntu-24.04 \
  --name log-analyzer-cloud \
  --memory 2G \
  --disk 10G \
  --cloud-init cloud-init/cloud-init.yaml

# Wait 3-5 minutes for deployment to complete
sleep 180

# Get VM IP address
VM_IP=$(multipass info log-analyzer-cloud | grep IPv4 | awk '{print $2}')
echo "Grafana: http://$VM_IP"
echo "Prometheus: http://$VM_IP/prometheus"
echo "Metrics: http://$VM_IP:8000/metrics"