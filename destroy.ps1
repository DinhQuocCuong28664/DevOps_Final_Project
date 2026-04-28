Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevOps Final Project — Destroy Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ============================================================
# BƯỚC 1: Gỡ bỏ Helm Releases (giải phóng LoadBalancer của Ingress)
# ============================================================
Write-Host "`n[1/5] Gỡ bỏ Helm Releases..." -ForegroundColor Yellow
helm uninstall ingress-nginx   -n ingress-nginx --ignore-not-found
helm uninstall cert-manager    -n cert-manager  --ignore-not-found
helm uninstall loki-stack      -n monitoring    --ignore-not-found
helm uninstall monitoring-stack -n monitoring   --ignore-not-found

# ============================================================
# BƯỚC 2: Xóa các Kubernetes Resources
# ============================================================
Write-Host "`n[2/5] Xóa các Kubernetes Resources..." -ForegroundColor Yellow

# App resources - Production
kubectl delete -f kubernetes/ingress-ssl.yaml --ignore-not-found
kubectl delete -f kubernetes/alerting-rules.yaml --ignore-not-found
kubectl delete -f kubernetes/hpa.yaml --ignore-not-found
kubectl delete -f kubernetes/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/service.yaml --ignore-not-found

# MongoDB resources - Production (PVC phải xóa để không block terraform destroy)
kubectl delete -f kubernetes/mongodb-deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/mongodb-service.yaml --ignore-not-found
kubectl delete -f kubernetes/mongodb-pvc.yaml --ignore-not-found

# Staging resources
kubectl delete -f kubernetes/staging/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/staging/service.yaml --ignore-not-found

# ============================================================
# BƯỚC 3: Xóa các Namespaces
# ============================================================
Write-Host "`n[3/5] Xóa các Namespaces..." -ForegroundColor Yellow
kubectl delete namespace ingress-nginx --ignore-not-found
kubectl delete namespace cert-manager --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found
kubectl delete namespace staging --ignore-not-found
kubectl delete namespace production --ignore-not-found

# ============================================================
# BƯỚC 4: Chờ AWS dọn dẹp Load Balancers
# ============================================================
Write-Host "`n[4/5] Đợi AWS dọn dẹp Load Balancers..." -ForegroundColor Cyan

$maxWait  = 300  # Tối đa 5 phút
$interval = 15   # Kiểm tra mỗi 15 giây
$elapsed  = 0

while ($elapsed -lt $maxWait) {
    $lbServices = kubectl get svc -A --field-selector spec.type=LoadBalancer --no-headers 2>$null
    if (-not $lbServices) {
        Write-Host "  ✅ Không còn LoadBalancer nào! (sau $elapsed giây)" -ForegroundColor Green
        break
    }
    Write-Host "  ⏳ Vẫn còn LoadBalancer... chờ thêm $interval giây (tổng: $elapsed/$maxWait giây)" -ForegroundColor Cyan
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if ($elapsed -ge $maxWait) {
    Write-Host "  ⚠️  Đã chờ $maxWait giây nhưng LoadBalancer vẫn chưa xóa xong!" -ForegroundColor Red
    Write-Host "  → Kiểm tra thủ công trên AWS Console trước khi tiếp tục." -ForegroundColor Red
    $confirm = Read-Host "  Vẫn muốn chạy terraform destroy không? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "  ❌ Đã hủy. Chạy lại script sau khi LB đã xóa xong." -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# BƯỚC 5: Terraform Destroy
# ============================================================
Write-Host "`n[5/5] Phá hủy hạ tầng AWS với Terraform..." -ForegroundColor Yellow

Write-Host ""
Write-Host "  ⚠️  CẢNH BÁO S3:" -ForegroundColor Red
Write-Host "  S3 bucket 'devops-final-uploads-dqc28664' có force_destroy = true" -ForegroundColor Red
Write-Host "  → Toàn bộ ảnh sản phẩm đã upload sẽ bị XÓA VĨNH VIỄN!" -ForegroundColor Red
Write-Host "  → Backup dữ liệu nếu cần trước khi tiếp tục." -ForegroundColor Red
$confirmS3 = Read-Host "  Xác nhận xóa toàn bộ S3 data? (y/n)"
if ($confirmS3 -ne "y") {
    Write-Host "  ❌ Đã hủy." -ForegroundColor Red
    exit 1
}

Push-Location -Path "infrastructure"
terraform destroy -auto-approve
Pop-Location

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  ✅ Dọn dẹp hoàn tất! AWS đã bay màu hết." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "⚠️  VIỆC CÒN LẠI (làm thủ công):" -ForegroundColor Red
Write-Host "   → Vào Hostinger DNS Panel: https://hpanel.hostinger.com" -ForegroundColor Red
Write-Host "   → Xóa bản ghi CNAME 'www' (trỏ vào Ingress ELB)" -ForegroundColor Red
Write-Host "   → Xóa bản ghi A 'jenkins' (trỏ vào Jenkins EIP)" -ForegroundColor Red
