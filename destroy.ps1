# ============================================================
# destroy.ps1 - DevOps Final Project - Full Teardown Script
# Cleanly removes all Kubernetes resources then destroys
# AWS infrastructure via Terraform.
# ============================================================

# ============================================================
# STEP 0: Fix UTF-8 BOM encoding before execution
# ============================================================
if (Test-Path "$PSScriptRoot\.agent\fix_encoding.ps1") {
    & "$PSScriptRoot\.agent\fix_encoding.ps1" | Out-Null
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevOps Final Project - Destroy Script"     -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# ============================================================
# STEP 1: Uninstall Helm Releases (release LoadBalancers first)
# ============================================================
Write-Host "`n[1/5] Uninstalling Helm releases..." -ForegroundColor Yellow
helm uninstall ingress-nginx    -n ingress-nginx --ignore-not-found
helm uninstall cert-manager     -n cert-manager  --ignore-not-found
helm uninstall loki-stack       -n monitoring    --ignore-not-found
helm uninstall monitoring-stack -n monitoring    --ignore-not-found

# Wait for AWS Load Balancer to be fully released before Terraform destroy.
# helm uninstall returns immediately but AWS needs ~60-90s to delete the ELB
# and release ENIs from subnets. Without this wait, terraform destroy fails
# with DependencyViolation on subnet and security group deletion.
Write-Host "  Waiting 90s for AWS Load Balancer to be fully released..." -ForegroundColor Cyan
Write-Host "  (This prevents DependencyViolation errors in terraform destroy)" -ForegroundColor Gray
$elapsed = 0
while ($elapsed -lt 90) {
    Start-Sleep -Seconds 10
    $elapsed += 10
    Write-Host "  Waiting... ($elapsed/90 sec)" -ForegroundColor Gray
}
Write-Host "  [OK] Load Balancer should be released now." -ForegroundColor Green

# ============================================================
# STEP 2: Delete Kubernetes Resources
# ============================================================
Write-Host "`n[2/5] Deleting Kubernetes resources..." -ForegroundColor Yellow

# App resources - Production
kubectl delete -f kubernetes/ingress-ssl.yaml       --ignore-not-found
kubectl delete -f kubernetes/alerting-rules.yaml    --ignore-not-found
kubectl delete -f kubernetes/prometheus-scrape.yaml --ignore-not-found
kubectl delete -f kubernetes/hpa.yaml               --ignore-not-found
kubectl delete -f kubernetes/deployment.yaml        --ignore-not-found
kubectl delete -f kubernetes/service.yaml           --ignore-not-found

# MongoDB resources (PVC must be deleted to unblock terraform destroy)
kubectl delete -f kubernetes/mongodb-deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/mongodb-service.yaml    --ignore-not-found
kubectl delete -f kubernetes/mongodb-pvc.yaml        --ignore-not-found

# Staging resources
kubectl delete -f kubernetes/staging/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/staging/service.yaml    --ignore-not-found
kubectl delete namespace staging                     --ignore-not-found

# ============================================================
# STEP 3: Delete Namespaces
# ============================================================
Write-Host "`n[3/5] Deleting namespaces..." -ForegroundColor Yellow
kubectl delete namespace ingress-nginx --ignore-not-found
kubectl delete namespace cert-manager  --ignore-not-found
kubectl delete namespace monitoring    --ignore-not-found
kubectl delete namespace staging       --ignore-not-found
kubectl delete namespace production    --ignore-not-found

# ============================================================
# STEP 4: Wait for AWS to clean up Load Balancers
# ============================================================
Write-Host "`n[4/5] Waiting for AWS to release Load Balancers..." -ForegroundColor Cyan

$maxWait  = 300   # Max 5 minutes
$interval = 15    # Check every 15 seconds
$elapsed  = 0

while ($elapsed -lt $maxWait) {
    $lbServices = kubectl get svc -A --field-selector spec.type=LoadBalancer --no-headers 2>$null
    if (-not $lbServices) {
        Write-Host "  [OK] No LoadBalancers remaining! (after $elapsed sec)" -ForegroundColor Green
        break
    }
    Write-Host "  LoadBalancers still exist... waiting $interval sec (total: $elapsed/$maxWait sec)" -ForegroundColor Cyan
    Start-Sleep -Seconds $interval
    $elapsed += $interval
}

if ($elapsed -ge $maxWait) {
    Write-Host "  [WARN] Waited $maxWait sec but LoadBalancers are still not released!" -ForegroundColor Red
    Write-Host "  -> Check manually on AWS Console before continuing." -ForegroundColor Red
    $confirm = Read-Host "  Continue with terraform destroy anyway? (y/n)"
    if ($confirm -ne "y") {
        Write-Host "  [CANCELLED] Aborted. Re-run after LoadBalancers are released." -ForegroundColor Red
        exit 1
    }
}

# ============================================================
# STEP 5: Terraform Destroy
# ============================================================
Write-Host "`n[5/5] Destroying AWS infrastructure with Terraform..." -ForegroundColor Yellow

Write-Host ""
Write-Host "  !! WARNING - S3 DATA LOSS !!" -ForegroundColor Red
Write-Host "  S3 bucket has force_destroy = true" -ForegroundColor Red
Write-Host "  -> ALL uploaded product images will be PERMANENTLY DELETED!" -ForegroundColor Red
Write-Host "  -> Back up your data before continuing if needed." -ForegroundColor Red
$confirmS3 = Read-Host "  Confirm permanent S3 deletion? (y/n)"
if ($confirmS3 -ne "y") {
    Write-Host "  [CANCELLED] Aborted." -ForegroundColor Red
    exit 1
}

Push-Location -Path "infrastructure"
terraform destroy -auto-approve
Pop-Location

Write-Host "`n============================================" -ForegroundColor Green
Write-Host "  [OK] Teardown complete! All AWS resources destroyed." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  MANUAL CLEANUP REQUIRED:" -ForegroundColor Red
Write-Host "  -> Go to Hostinger DNS: https://hpanel.hostinger.com" -ForegroundColor Red
Write-Host "  -> Remove CNAME 'www'      (was pointing to Ingress ELB)" -ForegroundColor Red
Write-Host "  -> Remove A record 'jenkins' (was pointing to Jenkins EIP)" -ForegroundColor Red
