Write-Host "Bắt đầu gỡ bỏ các Helm Releases..." -ForegroundColor Yellow
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall cert-manager -n cert-manager
helm uninstall monitoring-stack -n monitoring

Write-Host "`nXóa các Kubernetes Resources..." -ForegroundColor Yellow
kubectl delete -f kubernetes/ingress-ssl.yaml --ignore-not-found
kubectl delete -f kubernetes/alerting-rules.yaml --ignore-not-found
kubectl delete -f kubernetes/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/service.yaml --ignore-not-found
kubectl delete -f kubernetes/hpa.yaml --ignore-not-found
kubectl delete -f kubernetes/staging/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/staging/service.yaml --ignore-not-found

Write-Host "`nXóa các Namespaces..." -ForegroundColor Yellow
kubectl delete namespace ingress-nginx --ignore-not-found
kubectl delete namespace cert-manager --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found
kubectl delete namespace staging --ignore-not-found
kubectl delete namespace production --ignore-not-found

Write-Host "`nĐợi 10 giây để đảm bảo AWS dọn dẹp xong Load Balancers..." -ForegroundColor Cyan
Start-Sleep -Seconds 10

Write-Host "`nTiến hành phá hủy hạ tầng AWS với Terraform..." -ForegroundColor Yellow
Push-Location -Path "infrastructure"
terraform destroy -auto-approve
Pop-Location

Write-Host "`n🎉 Quá trình dọn dẹp hệ thống đã hoàn tất! Các tài nguyên AWS đều đã bay màu." -ForegroundColor Green
Write-Host "LƯU Ý: Vui lòng vào Hostinger Domain Panel (https://hpanel.hostinger.com) để xóa mục A 'jenkins' và CNAME 'www' !" -ForegroundColor Red
