#!/bin/bash
# ============================================================
# Auto-Install: Docker + Jenkins + Nginx + Certbot
# Script này chạy tự động khi EC2 khởi động (user-data)
# ============================================================

set -e

# Cập nhật hệ thống
apt-get update -y
apt-get upgrade -y

# ============================================================
# 1. Cài đặt Docker
# ============================================================
apt-get install -y ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Cho user ubuntu dùng docker không cần sudo
usermod -aG docker ubuntu

# ============================================================
# 2. Chạy Jenkins bằng Docker
# ============================================================
# Tạo volume để Jenkins lưu dữ liệu vĩnh viễn
docker volume create jenkins_home

# Chạy Jenkins container
docker run -d \
  --name jenkins \
  --restart=always \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts-jdk17

# ============================================================
# 3. Cài đặt Nginx (Reverse Proxy)
# ============================================================
apt-get install -y nginx

# Tạo config Nginx proxy cho Jenkins
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

        # Cần cho Jenkins WebSocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Tăng timeout cho các build lâu
        proxy_read_timeout 90s;
    }
}
NGINX_CONF

# Bật site, tắt default
ln -sf /etc/nginx/sites-available/jenkins /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ============================================================
# 4. Cài đặt Certbot (SSL/HTTPS tự động)
# ============================================================
apt-get install -y certbot python3-certbot-nginx

# Lưu ý: Certbot cần chạy THỦ CÔNG sau khi DNS A record đã trỏ đúng
# Lệnh: sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun

# ============================================================
# 5. Lưu mật khẩu admin ban đầu
# ============================================================
echo "============================================" >> /home/ubuntu/JENKINS_INFO.txt
echo "Jenkins Initial Admin Password:" >> /home/ubuntu/JENKINS_INFO.txt
echo "Chạy lệnh sau để lấy mật khẩu:" >> /home/ubuntu/JENKINS_INFO.txt
echo "docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword" >> /home/ubuntu/JENKINS_INFO.txt
echo "============================================" >> /home/ubuntu/JENKINS_INFO.txt
echo "URL: https://jenkins.moteo.fun" >> /home/ubuntu/JENKINS_INFO.txt
echo "============================================" >> /home/ubuntu/JENKINS_INFO.txt
