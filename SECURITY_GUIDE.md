# Security Hardening Guide: Log Analyzer Stack

## 🔒 Critical Security Measures Implemented

### 1. Firewall (UFW)
- **Allowed ports:** 22 (SSH), 80 (HTTP), 443 (HTTPS)
- **Blocked ports:** 3000 (Grafana direct), 9090 (Prometheus direct), 8000 (log analyzer direct)
- **Rationale:** All access must go through Nginx reverse proxy with rate limiting

### 2. Authentication
- Grafana: Default password changed from `admin/admin` to strong password
- SSH: Password authentication disabled, only key-based auth allowed
- Prometheus: Protected via Nginx basic auth

### 3. OS Hardening
- Unnecessary services disabled (avahi-daemon)
- Automatic security updates enabled (`unattended-upgrades`)
- Root login via SSH disabled

### 4. Rate Limiting (Nginx)
- 10 requests/second per IP for /api endpoints
- 5 requests/second per IP for login pages
- Protection against brute-force attacks

## 🚨 Critical Vulnerabilities Fixed

| Vulnerability | Risk Level | Fix Applied |
|---------------|------------|-------------|
| Direct access to Prometheus (:9090) | CRITICAL | Blocked via UFW + Nginx auth |
| Direct access to Grafana (:3000) | CRITICAL | Blocked via UFW + password change |
| UFW disabled | HIGH | Enabled with strict rules |
| Default Grafana password | HIGH | Changed to strong password |
| SSH password auth enabled | MEDIUM | Disabled, key-based auth only |

## 🔍 Verification Commands

### Check firewall status:
```bash
sudo ufw status numbered
```

### Check open ports:
```bash
sudo ss -tulpn | grep LISTEN
```

### Test blocked ports (should fail):
```bash
curl -I http://localhost:9090  # Should return connection refused
curl -I http://localhost:3000  # Should return connection refused
```

### Test allowed ports (should succeed):
```bash
curl -I http://localhost        # Should return HTTP 200/302
curl -I http://localhost/prometheus  # Should return HTTP 401 (auth required)
```

## 📌 Daily Security Checklist
Check /var/log/auth.log for failed SSH attempts
Verify unattended-upgrades installed security patches
Review Grafana audit logs for suspicious activity
Check disk space (df -h) to prevent log flooding attacks
