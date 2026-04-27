Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevOps Final Project — Destroy Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ============================================================
# BƯỚC 1: Gỡ bỏ Helm Releases (giải phóng LoadBalancer của Ingress)
# ============================================================
Write-Host "`n[1/5] Gỡ bỏ Helm Releases..." -ForegroundColor Yellow
helm uninstall ingress-nginx -n ingress-nginx --ignore-not-found
helm uninstall cert-manager -n cert-manager --ignore-not-found
helm uninstall monitoring-stack -n monitoring --ignore-not-found

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
Write-Host "  Kiểm tra LoadBalancer còn lại:" -ForegroundColor Cyan
kubectl get svc -A --field-selector spec.type=LoadBalancer 2>$null

Write-Host "  Đợi 90 giây để AWS xóa hoàn toàn Load Balancers..." -ForegroundColor Cyan
Start-Sleep -Seconds 90

Write-Host "  Kiểm tra lại sau khi chờ:" -ForegroundColor Cyan
kubectl get svc -A --field-selector spec.type=LoadBalancer 2>$null

# ============================================================
# BƯỚC 5: Terraform Destroy
# ============================================================
Write-Host "`n[5/5] Phá hủy hạ tầng AWS với Terraform..." -ForegroundColor Yellow
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
