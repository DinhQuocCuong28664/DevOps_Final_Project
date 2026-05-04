# ============================================================
# deploy.ps1 - DevOps Final Project - Full End-to-End Deployment
# ============================================================
# After this script completes, you only need to:
#   1. Set DNS records on Hostinger (instructions shown below)
#   2. Complete Jenkins setup wizard on https://jenkins.moteo.fun
# ============================================================

# Fix UTF-8 BOM encoding before execution
if (Test-Path "$PSScriptRoot\.agent\fix_encoding.ps1") {
    & "$PSScriptRoot\.agent\fix_encoding.ps1" | Out-Null
}

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  DevOps Final Project - Full Deploy"        -ForegroundColor Cyan
Write-Host "  Estimated time: ~30-40 minutes"            -ForegroundColor Cyan
Write-Host "============================================`n" -ForegroundColor Cyan

function ConvertTo-PlainText {
    param([Security.SecureString]$SecureValue)

    if (-not $SecureValue) {
        return ""
    }

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureValue)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

function Escape-HelmValue {
    param([string]$Value)

    return $Value.Replace("\", "\\").Replace(",", "\,").Replace("=", "\=")
}

function Import-DotEnv {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    Get-Content $Path | ForEach-Object {
        $line = $_.Trim()
        if (-not $line -or $line.StartsWith("#") -or -not $line.Contains("=")) {
            return
        }

        $key, $value = $line.Split("=", 2)
        $key = $key.Trim()
        $value = $value.Trim().Trim('"').Trim("'")

        if ($key) {
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
}

function Read-AlertEmailConfig {
    Import-DotEnv -Path (Join-Path $PSScriptRoot ".env")

    if ($env:ALERT_SMTP_USER -and $env:ALERT_SMTP_PASS -and $env:ALERT_TO) {
        $smtpHost = $env:ALERT_SMTP_HOST
        if ([string]::IsNullOrWhiteSpace($smtpHost)) {
            $smtpHost = "smtp.gmail.com:587"
        }

        Write-Host "Alertmanager email notification setup" -ForegroundColor Cyan
        Write-Host "  Loaded email alert settings from .env for receiver: $env:ALERT_TO" -ForegroundColor Green

        return @{
            SmtpHost = $smtpHost
            SmtpUser = $env:ALERT_SMTP_USER
            SmtpPass = $env:ALERT_SMTP_PASS
            AlertTo  = $env:ALERT_TO
        }
    }

    Write-Host "Alertmanager email notification setup" -ForegroundColor Cyan
    Write-Host "  Press Enter without an SMTP username to skip email and keep localhost:9093 UI only." -ForegroundColor Gray
    Write-Host "  For Gmail, use an App Password, not your normal Gmail password." -ForegroundColor Gray

    $smtpUser = Read-Host "  SMTP username/email"
    if ([string]::IsNullOrWhiteSpace($smtpUser)) {
        Write-Host "  Email alerting skipped. Alertmanager UI remains available through localhost:9093." -ForegroundColor Yellow
        return $null
    }

    $smtpPass = ConvertTo-PlainText (Read-Host "  SMTP app password" -AsSecureString)
    $alertTo = Read-Host "  Alert receiver email"
    $smtpHost = Read-Host "  SMTP host:port [smtp.gmail.com:587]"

    if ([string]::IsNullOrWhiteSpace($smtpHost)) {
        $smtpHost = "smtp.gmail.com:587"
    }

    if ([string]::IsNullOrWhiteSpace($smtpPass) -or [string]::IsNullOrWhiteSpace($alertTo)) {
        Write-Host "  Incomplete email settings. Email alerting skipped." -ForegroundColor Yellow
        return $null
    }

    return @{
        SmtpHost = $smtpHost
        SmtpUser = $smtpUser
        SmtpPass = $smtpPass
        AlertTo  = $alertTo
    }
}

$alertEmailConfig = Read-AlertEmailConfig

# ============================================================
# STEP 1: Terraform - Provision AWS Infrastructure
# ============================================================
Write-Host "[1/8] Provisioning AWS infrastructure with Terraform..." -ForegroundColor Yellow
Write-Host "  This will take approximately 15-20 minutes..." -ForegroundColor Gray

Push-Location -Path "infrastructure"
terraform init -upgrade
terraform apply -auto-approve
Pop-Location

Write-Host "  [OK] Infrastructure created!" -ForegroundColor Green

# Read Terraform outputs
$jenkinsIp  = terraform -chdir="infrastructure" output -raw jenkins_public_ip   2>$null
$jenkinsSsh = terraform -chdir="infrastructure" output -raw jenkins_ssh          2>$null
$s3Bucket   = terraform -chdir="infrastructure" output -raw s3_uploads_bucket_name 2>$null
$keyFile    = "infrastructure\jenkins-key.pem"

Write-Host ""
Write-Host "  =============================" -ForegroundColor Magenta
Write-Host "  Jenkins IP : $jenkinsIp"       -ForegroundColor Magenta
Write-Host "  S3 Bucket  : $s3Bucket"        -ForegroundColor Magenta
Write-Host "  =============================" -ForegroundColor Magenta

# ============================================================
# STEP 2: Connect kubectl to EKS Cluster
# ============================================================
Write-Host "`n[2/8] Connecting kubectl to EKS Cluster..." -ForegroundColor Yellow
aws eks update-kubeconfig --region ap-southeast-2 --name devops-final-cluster

Write-Host "  Waiting for EKS nodes to be Ready..." -ForegroundColor Cyan
$maxWait = 300
$elapsed = 0
while ($elapsed -lt $maxWait) {
    $readyNodes = kubectl get nodes --no-headers 2>$null | Where-Object { $_ -match " Ready " }
    if (($readyNodes | Measure-Object).Count -ge 2) {
        Write-Host "  [OK] EKS cluster ready! (2 nodes)" -ForegroundColor Green
        break
    }
    Write-Host "  Waiting for nodes... ($elapsed/$maxWait sec)" -ForegroundColor Cyan
    Start-Sleep -Seconds 20
    $elapsed += 20
}
kubectl get nodes

# ============================================================
# STEP 3: Install NGINX Ingress Controller
# ============================================================
Write-Host "`n[3/8] Installing NGINX Ingress Controller..." -ForegroundColor Yellow
helm repo add ingress-nginx        https://kubernetes.github.io/ingress-nginx  2>$null
helm repo add jetstack             https://charts.jetstack.io                   2>$null
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>$null
helm repo add grafana              https://grafana.github.io/helm-charts        2>$null
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx `
    --namespace ingress-nginx --create-namespace

Write-Host "  Waiting for LoadBalancer EXTERNAL-IP..." -ForegroundColor Cyan
$elbHostname = ""
$elapsed = 0
while ($elapsed -lt 180) {
    $elbHostname = kubectl get svc -n ingress-nginx ingress-nginx-controller `
        -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>$null
    if ($elbHostname) {
        Write-Host "  [OK] Ingress ELB ready!" -ForegroundColor Green
        break
    }
    Write-Host "  Waiting for EXTERNAL-IP... ($elapsed/180 sec)" -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    $elapsed += 15
}

# ============================================================
# STEP 4: Install Cert-Manager
# ============================================================
Write-Host "`n[4/8] Installing Cert-Manager..." -ForegroundColor Yellow
helm upgrade --install cert-manager jetstack/cert-manager `
    --namespace cert-manager --create-namespace `
    --set crds.enabled=true
Write-Host "  [OK] Cert-Manager installed!" -ForegroundColor Green

# ============================================================
# STEP 5: Install Monitoring Stack (Prometheus + Grafana + Loki)
# ============================================================
Write-Host "`n[5/8] Installing Prometheus + Grafana + Loki..." -ForegroundColor Yellow

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

$monitoringHelmArgs = @(
    "upgrade", "--install", "monitoring-stack", "prometheus-community/kube-prometheus-stack",
    "--namespace", "monitoring", "--create-namespace"
)

if ($alertEmailConfig) {
    Write-Host "  Configuring Alertmanager email receiver: $($alertEmailConfig.AlertTo)" -ForegroundColor Cyan
    $monitoringHelmArgs += @(
        "--set", "alertmanager.config.global.smtp_smarthost=$(Escape-HelmValue $alertEmailConfig.SmtpHost)",
        "--set", "alertmanager.config.global.smtp_from=$(Escape-HelmValue $alertEmailConfig.SmtpUser)",
        "--set", "alertmanager.config.global.smtp_auth_username=$(Escape-HelmValue $alertEmailConfig.SmtpUser)",
        "--set", "alertmanager.config.global.smtp_auth_password=$(Escape-HelmValue $alertEmailConfig.SmtpPass)",
        "--set", "alertmanager.config.global.smtp_require_tls=true",
        "--set", "alertmanager.config.route.group_by[0]=alertname",
        "--set", "alertmanager.config.route.group_wait=30s",
        "--set", "alertmanager.config.route.group_interval=5m",
        "--set", "alertmanager.config.route.repeat_interval=2h",
        "--set", "alertmanager.config.route.receiver=email-alerts",
        "--set", "alertmanager.config.receivers[0].name=email-alerts",
        "--set", "alertmanager.config.receivers[0].email_configs[0].to=$(Escape-HelmValue $alertEmailConfig.AlertTo)",
        "--set", "alertmanager.config.receivers[0].email_configs[0].send_resolved=true",
        "--set", "alertmanager.config.receivers[1].name=null"
    )
}
else {
    Write-Host "  Installing Alertmanager without email receiver; use localhost:9093 for alert verification." -ForegroundColor Yellow
}

helm @monitoringHelmArgs

helm upgrade --install loki-stack grafana/loki-stack `
    --namespace monitoring `
    --values kubernetes/loki-values.yaml

Write-Host "  [OK] Monitoring + Logging stack installed!" -ForegroundColor Green

$grafanaPass = kubectl --namespace monitoring get secrets monitoring-stack-grafana `
    -o jsonpath="{.data.admin-password}" 2>$null | ForEach-Object {
        [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_))
    }

# ============================================================
# STEP 6: Apply All Kubernetes Manifests
# ============================================================
Write-Host "`n[6/8] Applying all Kubernetes manifests..." -ForegroundColor Yellow

# Create namespaces (idempotent)
kubectl create namespace production --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace staging    --dry-run=client -o yaml | kubectl apply -f -
Write-Host "  [OK] Namespaces ready (production, staging)" -ForegroundColor Green

# MongoDB
kubectl apply -f kubernetes/mongodb-pvc.yaml
kubectl apply -f kubernetes/mongodb-deployment.yaml
kubectl apply -f kubernetes/mongodb-service.yaml
Write-Host "  [OK] MongoDB applied" -ForegroundColor Green

# Application (staging) — deploy first for validation
# IMPORTANT: Replace IMAGE_TAG_PLACEHOLDER with the Git commit SHA
# STANDARD RULE: Images must use explicit version tags (commit SHA), NEVER 'latest'
$gitSha = git rev-parse --short HEAD
Write-Host "  Using image tag: $gitSha (from Git commit SHA)" -ForegroundColor Cyan
(Get-Content kubernetes/staging/deployment.yaml) -replace 'IMAGE_TAG_PLACEHOLDER', $gitSha | kubectl apply -f -
kubectl apply -f kubernetes/staging/service.yaml
kubectl apply -f kubernetes/staging/ingress-ssl.yaml
Write-Host "  [OK] Application (staging) applied" -ForegroundColor Green

# Application (production) — deploy after staging
(Get-Content kubernetes/deployment.yaml) -replace 'IMAGE_TAG_PLACEHOLDER', $gitSha | kubectl apply -f -
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/hpa.yaml
Write-Host "  [OK] Application (production) applied" -ForegroundColor Green

# Ingress SSL + Monitoring rules
kubectl apply -f kubernetes/ingress-ssl.yaml
kubectl apply -f kubernetes/alerting-rules.yaml
kubectl apply -f kubernetes/prometheus-scrape.yaml
Write-Host "  [OK] Ingress, Alerting, ServiceMonitor applied" -ForegroundColor Green

# ============================================================
# STEP 7: DNS - Show instructions and wait for confirmation
# ============================================================
Write-Host "`n[7/8] DNS Configuration Required" -ForegroundColor Red
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Red
Write-Host "  ACTION REQUIRED: Set DNS records on Hostinger" -ForegroundColor Red
Write-Host "  Go to: https://hpanel.hostinger.com -> Domains -> moteo.fun -> DNS Records" -ForegroundColor Red
Write-Host ""
Write-Host "  1. CNAME  www      -> $elbHostname" -ForegroundColor Yellow
Write-Host "  2. CNAME  staging  -> $elbHostname" -ForegroundColor Yellow
Write-Host "  3. A      jenkins  -> $jenkinsIp"   -ForegroundColor Yellow
Write-Host ""
Write-Host "  (Delete old conflicting records first if any)" -ForegroundColor Gray
Write-Host "  ============================================" -ForegroundColor Red
Write-Host ""

# Wait for user to confirm DNS is set
Read-Host "  Press ENTER after you have set all DNS records..."

# Poll until jenkins.moteo.fun resolves to the correct IP
Write-Host "  Waiting for jenkins.moteo.fun DNS to propagate..." -ForegroundColor Cyan
$dnsOk = $false
$elapsed = 0
while ($elapsed -lt 300) {
    try {
        $resolved = [System.Net.Dns]::GetHostAddresses("jenkins.moteo.fun") | Select-Object -First 1
        if ($resolved.IPAddressToString -eq $jenkinsIp) {
            Write-Host "  [OK] DNS propagated! jenkins.moteo.fun -> $jenkinsIp" -ForegroundColor Green
            $dnsOk = $true
            break
        }
    } catch {}
    Write-Host "  DNS not ready yet... ($elapsed/300 sec)" -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    $elapsed += 15
}

# ============================================================
# STEP 8: Enable HTTPS on Jenkins via Certbot (auto SSH)
# ============================================================
Write-Host "`n[8/8] Setting up HTTPS for Jenkins..." -ForegroundColor Yellow

if ($dnsOk -and (Test-Path $keyFile)) {
    Write-Host "  SSH-ing into Jenkins to run Certbot..." -ForegroundColor Cyan

    # Wait for Jenkins container to be fully up before requesting cert
    Start-Sleep -Seconds 15

    $certbotCmd = "sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun"
    ssh -i $keyFile -o StrictHostKeyChecking=no ubuntu@$jenkinsIp $certbotCmd

    if ($LASTEXITCODE -eq 0) {
        Write-Host "  [OK] SSL certificate issued! Jenkins HTTPS is ready." -ForegroundColor Green
    } else {
        Write-Host "  [WARN] Certbot failed. Run manually on Jenkins server:" -ForegroundColor Yellow
        Write-Host "    ssh -i $keyFile ubuntu@$jenkinsIp" -ForegroundColor Gray
        Write-Host "    sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun" -ForegroundColor Gray
    }
} elseif (-not (Test-Path $keyFile)) {
    Write-Host "  [WARN] Key file not found at $keyFile - run Certbot manually." -ForegroundColor Yellow
} else {
    Write-Host "  [WARN] DNS not fully propagated - run Certbot manually after DNS is ready:" -ForegroundColor Yellow
    Write-Host "    ssh -i $keyFile ubuntu@$jenkinsIp" -ForegroundColor Gray
    Write-Host "    sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun" -ForegroundColor Gray
}

# ============================================================
# FINAL SUMMARY
# ============================================================
Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "  [OK] DEPLOYMENT COMPLETE!"                -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  --- Infrastructure ---" -ForegroundColor Cyan
kubectl get nodes
Write-Host ""
Write-Host "  --- Pods (ingress-nginx) ---" -ForegroundColor Cyan
kubectl get pods -n ingress-nginx
Write-Host ""
Write-Host "  --- Pods (production) ---" -ForegroundColor Cyan
kubectl get pods -n production
Write-Host ""
Write-Host "  --- Pods (monitoring) ---" -ForegroundColor Cyan
kubectl get pods -n monitoring
Write-Host ""
Write-Host "  ============================================" -ForegroundColor Green
Write-Host "  Access the system:" -ForegroundColor Green
Write-Host "  [App]     https://www.moteo.fun" -ForegroundColor Green
Write-Host "  [Jenkins] https://jenkins.moteo.fun" -ForegroundColor Green
Write-Host "  [Grafana] Run: kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80" -ForegroundColor Green
Write-Host "            Then open: http://localhost:3000 (admin / $grafanaPass)" -ForegroundColor Green
Write-Host "  [Loki]    Grafana -> Explore -> Data Source: Loki -> {namespace='production'}" -ForegroundColor Green
Write-Host ""
Write-Host "  --- Jenkins Setup ---" -ForegroundColor Yellow
Write-Host "  SSH:      ssh -i $keyFile ubuntu@$jenkinsIp" -ForegroundColor Yellow
Write-Host "  Password: docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword" -ForegroundColor Yellow
Write-Host "  ============================================" -ForegroundColor Green
