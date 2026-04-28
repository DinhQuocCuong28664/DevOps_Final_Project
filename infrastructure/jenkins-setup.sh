#!/bin/bash
# ============================================================
# Auto-Install: Docker + Jenkins + Nginx + Certbot
# This script runs automatically on EC2 boot (user-data)
# ============================================================

set -e

# Update system packages
apt-get update -y
apt-get upgrade -y

# ============================================================
# 1. Install Docker
# ============================================================
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Allow ubuntu user to use docker without sudo
usermod -aG docker ubuntu

# ============================================================
# 2. Run Jenkins via Docker
# ============================================================
# Create a persistent volume for Jenkins data
docker volume create jenkins_home

# Start Jenkins container
docker run -d \
  --name jenkins \
  --restart=always \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17

# ============================================================
# 3. Install Nginx (Reverse Proxy)
# ============================================================
apt-get install -y nginx

# Create Nginx proxy config for Jenkins
cat > /etc/nginx/sites-available/jenkins <<'NGINX_CONF'
server {
    listen 80;
    server_name jenkins.moteo.fun;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Required for Jenkins WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Increase timeout for long builds
        proxy_read_timeout 90s;
    }
}
NGINX_CONF

# Enable site, disable default
ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ============================================================
# 4. Install Certbot (automatic SSL/HTTPS)
# ============================================================
apt-get install -y certbot python3-certbot-nginx

# Note: Certbot must be run MANUALLY after DNS A record is pointing correctly
# Command: sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun

# ============================================================
# 5. Save initial admin password info
# ============================================================
echo "============================================" >> /home/ubuntu/JENKINS_INFO.txt
echo "Jenkins Initial Admin Password:" >> /home/ubuntu/JENKINS_INFO.txt
echo "Run the following command to get the password:" >> /home/ubuntu/JENKINS_INFO.txt
echo "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword" >> /home/ubuntu/JENKINS_INFO.txt
echo "============================================" >> /home/ubuntu/JENKINS_INFO.txt
echo "URL: https://jenkins.moteo.fun" >> /home/ubuntu/JENKINS_INFO.txt
echo "============================================" >> /home/ubuntu/JENKINS_INFO.txt
