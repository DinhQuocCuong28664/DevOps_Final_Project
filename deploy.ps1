Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevOps Final Project — Deploy Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  Script tự động hóa toàn bộ quá trình" -ForegroundColor Cyan
Write-Host "  khởi động hệ thống từ đầu (~30-35 phút)" -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

# ============================================================
# BƯỚC 1: Terraform — Tạo VPC + EKS + Jenkins EC2
# ============================================================
Write-Host "[1/7] Khởi tạo hạ tầng AWS với Terraform..." -ForegroundColor Yellow
Write-Host "  ⏱️  Sẽ mất khoảng 15-20 phút..." -ForegroundColor Gray

Push-Location -Path "infrastructure"
terraform init -upgrade
terraform apply -auto-approve
Pop-Location

Write-Host "  ✅ Hạ tầng đã được tạo!" -ForegroundColor Green

# Lấy Jenkins IP và S3 bucket name từ terraform output
$jenkinsIp   = terraform -chdir="infrastructure" output -raw jenkins_public_ip 2>$null
$s3Bucket    = terraform -chdir="infrastructure" output -raw s3_uploads_bucket_name 2>$null
Write-Host ""
Write-Host "  =============================" -ForegroundColor Magenta
Write-Host "  Jenkins IP  : $jenkinsIp" -ForegroundColor Magenta
Write-Host "  S3 Bucket   : $s3Bucket (ap-southeast-2)" -ForegroundColor Magenta
Write-Host "  → Cần thêm A record 'jenkins' trỏ vào IP này trên Hostinger!" -ForegroundColor Magenta
Write-Host "  =============================" -ForegroundColor Magenta

# ============================================================
# BƯỚC 2: Kết nối kubectl vào EKS
# ============================================================
Write-Host "`n[2/7] Kết nối kubectl vào EKS Cluster..." -ForegroundColor Yellow
aws eks update-kubeconfig --region ap-southeast-2 --name devops-final-cluster

# Chờ nodes sẵn sàng (polling)
Write-Host "  Đợi EKS nodes Ready..." -ForegroundColor Cyan
$maxWait = 300
$elapsed = 0
while ($elapsed -lt $maxWait) {
    $readyNodes = kubectl get nodes --no-headers 2>$null | Where-Object { $_ -match " Ready " }
    if (($readyNodes | Measure-Object).Count -ge 2) {
        Write-Host "  ✅ EKS cluster sẵn sàng! (2 nodes Ready)" -ForegroundColor Green
        break
    }
    Write-Host "  ⏳ Chưa đủ nodes Ready... ($elapsed/$maxWait giây)" -ForegroundColor Cyan
    Start-Sleep -Seconds 20
    $elapsed += 20
}
kubectl get nodes

# ============================================================
# BƯỚC 3: Cài đặt NGINX Ingress Controller
# ============================================================
Write-Host "`n[3/7] Cài đặt NGINX Ingress Controller..." -ForegroundColor Yellow
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>$null
helm repo add jetstack https://charts.jetstack.io 2>$null
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
helm repo add grafana https://grafana.github.io/helm-charts 2>$null
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-nginx --create-namespace

# Chờ Ingress có EXTERNAL-IP (polling)
Write-Host "  Đợi LoadBalancer có EXTERNAL-IP..." -ForegroundColor Cyan
$elapsed = 0
while ($elapsed -lt 180) {
    $externalIp = kubectl get svc -n ingress-nginx ingress-nginx-controller `
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($externalIp) {
        Write-Host "  ✅ Ingress LoadBalancer sẵn sàng!" -ForegroundColor Green
        Write-Host ""
        Write-Host "  =============================" -ForegroundColor Magenta
        Write-Host "  Ingress ELB: $externalIp" -ForegroundColor Magenta
        Write-Host "  → Cần thêm CNAME 'www' trỏ vào địa chỉ này trên Hostinger!" -ForegroundColor Magenta
        Write-Host "  =============================" -ForegroundColor Magenta
        break
    }
    Write-Host "  ⏳ Đang chờ EXTERNAL-IP... ($elapsed/180 giây)" -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    $elapsed += 15
}

# ============================================================
# BƯỚC 4: Cài đặt Cert-Manager (SSL tự động)
# ============================================================
Write-Host "`n[4/7] Cài đặt Cert-Manager..." -ForegroundColor Yellow
helm upgrade --install cert-manager jetstack/cert-manager `
    --namespace cert-manager --create-namespace `
    --set crds.enabled=true
Write-Host "  ✅ Cert-Manager đã cài xong!" -ForegroundColor Green

# ============================================================
# BƯỚC 5: Cài đặt Metrics Server + Monitoring Stack
# ============================================================
Write-Host "`n[5/7] Cài đặt Metrics Server + Prometheus + Grafana + Loki..." -ForegroundColor Yellow

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

helm upgrade --install monitoring-stack prometheus-community/kube-prometheus-stack `
    --namespace monitoring --create-namespace

# Cài Loki Stack (Loki + Promtail) — dùng lại Grafana có sẵn
Write-Host "  Cài đặt Loki Stack (Centralized Logging)..." -ForegroundColor Cyan
helm upgrade --install loki-stack grafana/loki-stack `
    --namespace monitoring `
    --values kubernetes/loki-values.yaml

Write-Host "  ✅ Monitoring + Logging stack đã cài xong!" -ForegroundColor Green

# Lấy mật khẩu Grafana
$grafanaPass = kubectl --namespace monitoring get secrets monitoring-stack-grafana `
    -o jsonpath="{.data.admin-password}" 2>$null | ForEach-Object {
        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
    }
Write-Host ""
Write-Host "  =============================" -ForegroundColor Magenta
Write-Host "  Grafana URL  : http://localhost:3000 (sau khi port-forward)" -ForegroundColor Magenta
Write-Host "  Grafana User : admin" -ForegroundColor Magenta
Write-Host "  Grafana Pass : $grafanaPass" -ForegroundColor Magenta
Write-Host "  Port-forward : kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80" -ForegroundColor Magenta
Write-Host "  ————————————————————————" -ForegroundColor Magenta
Write-Host "  Loki (Logs)  : Đã tích hợp vào Grafana (Data Source: Loki)" -ForegroundColor Magenta
Write-Host "  LogQL mẫu   : {namespace='production'} |= 'error'" -ForegroundColor Magenta
Write-Host "  =============================" -ForegroundColor Magenta

# ============================================================
# BƯỚC 6: Apply K8s manifests (Ingress SSL + Alerting Rules)
# ============================================================
Write-Host "`n[6/7] Apply Kubernetes manifests..." -ForegroundColor Yellow
kubectl apply -f kubernetes/ingress-ssl.yaml
kubectl apply -f kubernetes/alerting-rules.yaml
kubectl apply -f kubernetes/prometheus-scrape.yaml
Write-Host "  ✅ Ingress SSL, Alerting Rules và Prometheus ServiceMonitor đã được apply!" -ForegroundColor Green

Write-Host "  Đợi SSL certificate được cấp (có thể mất 2-3 phút sau khi DNS trỏ đúng)..." -ForegroundColor Cyan
Write-Host "  Kiểm tra: kubectl get certificate -n production" -ForegroundColor Gray

# ============================================================
# BƯỚC 7: Tóm tắt và việc còn lại
# ============================================================
Write-Host "`n[7/7] Kiểm tra tổng thể..." -ForegroundColor Yellow
Write-Host ""
kubectl get nodes
Write-Host ""
kubectl get pods -n ingress-nginx
Write-Host ""
kubectl get pods -n cert-manager
Write-Host ""
kubectl get pods -n monitoring

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  ✅ Deploy hoàn tất!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  VIỆC CÒN LẠI (làm thủ công trên Hostinger):" -ForegroundColor Red
Write-Host "   1. Vào: https://hpanel.hostinger.com → Domains → moteo.fun → DNS Records" -ForegroundColor Red
Write-Host "   2. Thêm/Sửa CNAME 'www'    → trỏ vào Ingress ELB ở trên" -ForegroundColor Red
Write-Host "   3. Thêm/Sửa A record 'jenkins' → trỏ vào Jenkins IP ở trên" -ForegroundColor Red
Write-Host "   4. Đợi DNS propagate (1-5 phút)" -ForegroundColor Red
Write-Host ""
Write-Host "   Sau khi DNS xong — SSH vào Jenkins để setup:" -ForegroundColor Yellow
$sshCmd = terraform -chdir="infrastructure" output -raw jenkins_ssh 2>$null
Write-Host "   $sshCmd" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Truy cập hệ thống:" -ForegroundColor Green
Write-Host "   🌐 App     : https://www.moteo.fun" -ForegroundColor Green
Write-Host "   🔧 Jenkins : https://jenkins.moteo.fun" -ForegroundColor Green
Write-Host "   📊 Grafana : kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80" -ForegroundColor Green
Write-Host "   📄 Loki Logs: Grafana → Explore → Data Source: Loki → {namespace=\"production\"}" -ForegroundColor Green
