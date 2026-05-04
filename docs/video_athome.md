# 🎬 Video Demonstration Guide

## Full End-to-End Demo — Production-Grade CI/CD System

| | |
|---|---|
| **Course** | Software Deployment, Operations & Maintenance |
| **Architecture** | Tier 5 – Expert: Kubernetes-Based Architecture (Amazon EKS) |
| **Production URL** | [https://www.moteo.fun](https://www.moteo.fun) |
| **Repository** | [github.com/DinhQuocCuong28664/DevOps_Final_Project](https://github.com/DinhQuocCuong28664/DevOps_Final_Project) |
| **Docker Hub** | [hub.docker.com/r/dinhquoccuong286/devops-final-app](https://hub.docker.com/r/dinhquoccuong286/devops-final-app) |
| **Jenkins** | [https://jenkins.moteo.fun](https://jenkins.moteo.fun) |

---

## 📑 Mục Lục

1. [Chuẩn bị trước khi quay](#1-chuẩn-bị-trước-khi-quay)
2. [5.1 — Source Code Modification](#51--source-code-modification)
3. [5.2 — Commit and Push](#52--commit-and-push)
4. [5.3 — CI Pipeline Execution](#53--ci-pipeline-execution)
5. [5.4 — CD Deployment](#54--cd-deployment)
6. [5.5 — Verification of Application Update](#55--verification-of-application-update)
7. [5.6 — Monitoring and Observability Validation](#56--monitoring-and-observability-validation)
8. [5.7 — Failure Simulation](#57--failure-simulation)
9. [Bonus: Jenkins Self-Hosted CI/CD](#bonus-jenkins-self-hosted-cicd)
10. [Bonus: Automated Rollback](#bonus-automated-rollback)
11. [Checklist sau khi quay](#checklist-sau-khi-quay)

---

## 1. Chuẩn bị trước khi quay

### 1.1 Kiểm tra cluster

```powershell
# Kiểm tra tất cả pods đều Running
kubectl get pods -A

# Kiểm tra production namespace (phải có 2 pods)
kubectl get pods -n production

# Kiểm tra HPA
kubectl get hpa -n production

# Kiểm tra ingress + TLS
kubectl get ingress -n production
kubectl get certificate -n production

# Kiểm tra monitoring
kubectl get pods -n monitoring
```

### 1.2 Mở sẵn các cửa sổ

| Cửa sổ | Nội dung | Ghi chú |
|--------|----------|---------|
| **VS Code** | `application/views/partials/head.ejs` | File sẽ sửa |
| **Terminal 1** | PowerShell ở `c:\Users\cbzer\DevOps_Final` | Để chạy lệnh |
| **Terminal 2** | `kubectl get pods -n production -w` | Watch pods |
| **Browser Tab 1** | `https://www.moteo.fun` | Production URL |
| **Browser Tab 2** | GitHub → Actions → Workflow runs | CI/CD pipeline |
| **Browser Tab 3** | Grafana `http://localhost:3001` | Monitoring |
| **Browser Tab 4** | Alertmanager `http://localhost:9093` | Alerts |
| **Browser Tab 5** | Docker Hub → Tags | Container images |

### 1.3 Port-forward (chạy trước khi quay)

```powershell
# Terminal A: Grafana
kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3001:80

# Terminal B: Alertmanager
kubectl port-forward -n monitoring svc/monitoring-stack-kube-prom-alertmanager 9093:9093
```

### 1.4 Grafana login

- **URL**: `http://localhost:3001`
- **Username**: `admin`
- **Password**: `Mzz7zSOwSkUei90wNHHH2TDpqkBhPHubJLMeaMht`

---

## 2. 5.1 — Source Code Modification

### Mục tiêu
Thay đổi source code để có thể thấy sự khác biệt sau deploy.

### Script thực hiện

```powershell
# Bước 1: Mở file head.ejs trong VS Code
code application/views/partials/head.ejs

# Bước 2: Trong VS Code, tìm dòng số 6:
#   <title>Moteo Store - Product Catalog</title>
# Sửa thành:
#   <title>Moteo Store v2.0 - DevOps Demo</title>

# Bước 3: Lưu file (Ctrl+S)
```

### Nội dung thay đổi cụ thể

**Trước khi sửa (dòng 6):**
```ejs
<title>Moteo Store - Product Catalog</title>
```

**Sau khi sửa:**
```ejs
<title>Moteo Store v2.0 - DevOps Demo</title>
```

### 🎥 Góc quay
- **Màn hình**: VS Code — show file `head.ejs` trước khi sửa → sửa title → lưu file
- **Thuyết minh**: "Chúng tôi sẽ thay đổi source code, cụ thể là sửa title của trang web từ 'Moteo Store - Product Catalog' thành 'Moteo Store v2.0 - DevOps Demo'. Đây là thay đổi có thể nhìn thấy được sau khi deploy."

---

## 3. 5.2 — Commit and Push

### Mục tiêu
Commit thay đổi và push lên GitHub để trigger CI/CD pipeline.

### Script thực hiện

```powershell
# Bước 1: Kiểm tra trạng thái file đã sửa
git status
# Output: modified:   application/views/partials/head.ejs

# Bước 2: Stage file đã sửa
git add application/views/partials/head.ejs

# Bước 3: Commit với message rõ ràng
git commit -m "feat: update UI title for DevOps demo video"

# Bước 4: Push lên GitHub (tự động trigger pipeline)
git push
```

### 🎥 Góc quay
- **Màn hình**: Terminal — show `git status` → `git add` → `git commit` → `git push`
- **Thuyết minh**: "Sau khi sửa code, chúng tôi dùng git status để kiểm tra, git add để stage file, git commit với message rõ ràng, và git push lên GitHub. Việc này sẽ tự động trigger GitHub Actions pipeline."

---

## 4. 5.3 — CI Pipeline Execution

### Mục tiêu
Show từng stage của CI pipeline chạy thành công.

### Script thực hiện

```powershell
# Bước 1: Mở GitHub Actions trong browser
start https://github.com/DinhQuocCuong28664/DevOps_Final_Project/actions

# Bước 2: Click vào workflow run vừa được trigger (commit mới nhất)
# Bước 3: Chờ pipeline chạy qua từng stage
```

### Các stage trong pipeline

| Stage | Nội dung | Thời gian |
|-------|----------|-----------|
| **1. Lint** | ESLint v9 — 0 errors | ~30s |
| **2. Cache** | npm cache restore/save | ~10s |
| **3. Build** | Docker multi-stage build | ~60s |
| **4. Security Scan** | Trivy — 0 vulnerabilities | ~30s |
| **5. Docker Push** | Push to Docker Hub (tag = commit SHA) | ~30s |

### Click vào từng stage để show log

```yaml
# Stage 1 - Lint log:
Run npx eslint .
# ... 0 errors, 7 warnings (or 0)

# Stage 3 - Build log:
# docker build -t dinhquoccuong286/devops-final-app:<SHA> .
# Successfully built ...

# Stage 4 - Trivy log:
# Total: 0 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 0, CRITICAL: 0)

# Stage 5 - Docker Push log:
# The push refers to repository [docker.io/dinhquoccuong286/devops-final-app]
# <SHA>: digest: sha256:... size: ...
```

### 🎥 Góc quay
- **Màn hình**: Browser — GitHub Actions pipeline overview → từng stage detail
- **Thuyết minh**: 
  - "Pipeline CI có 5 stages: Lint kiểm tra code quality, Cache tối ưu dependencies, Build tạo Docker image multi-stage, Trivy scan bảo mật, và cuối cùng push image lên Docker Hub."
  - "Mỗi stage đều pass, image được tag bằng commit SHA để đảm bảo traceability."

---

## 5. 5.4 — CD Deployment

### Mục tiêu
Show quá trình deploy qua 2 môi trường: Staging → Production.

### Script thực hiện

```powershell
# Bước 1: Sau khi CI pass, job deploy-staging tự động chạy
# Mở GitHub Actions để xem

# Bước 2: Kiểm tra staging deployment
kubectl get pods -n staging
kubectl rollout status deployment -n staging
# Output: deployment "devops-final-deployment" successfully rolled out

# Bước 3: Manual Approval - Mở GitHub → Environment "production"
# Click "Review deployments" → Approve and Deploy

# Bước 4: Sau khi approve, job deploy-production chạy
# Kiểm tra production deployment
kubectl get pods -n production
kubectl rollout status deployment -n production
# Output: deployment "devops-final-deployment" successfully rolled out
```

### Pipeline CD chi tiết

```yaml
# deploy-staging job:
#   - sed thay IMAGE_TAG_PLACEHOLDER bằng commit SHA mới
#   - kubectl apply -f kubernetes/staging/namespace.yaml
#   - kubectl apply -f kubernetes/staging/deployment.yaml
#   - kubectl apply -f kubernetes/staging/service.yaml
#   - kubectl rollout status deployment -n staging

# deploy-production job (sau manual approve):
#   - sed thay IMAGE_TAG_PLACEHOLDER
#   - kubectl apply -f kubernetes/production/namespace.yaml
#   - kubectl apply -f kubernetes/deployment.yaml
#   - kubectl apply -f kubernetes/service.yaml
#   - kubectl apply -f kubernetes/hpa.yaml
#   - kubectl rollout status deployment -n production
```

### 🎥 Góc quay
- **Màn hình**: Browser (GitHub Actions) → Terminal (kubectl)
- **Thuyết minh**: 
  - "CD pipeline tự động deploy lên staging trước."
  - "Sau đó cần manual approve từ reviewer để deploy lên production — đây là approval gate đảm bảo an toàn."
  - "Production dùng RollingUpdate strategy với maxUnavailable=0 để zero-downtime deployment."

---

## 6. 5.5 — Verification of Application Update

### Mục tiêu
Xác nhận ứng dụng đã được cập nhật với thay đổi.

### Script thực hiện

```powershell
# Bước 1: Mở production URL trong browser
start https://www.moteo.fun

# Bước 2: Kiểm tra response headers
curl -I https://www.moteo.fun
# Output:
# HTTP/2 200
# content-type: text/html; charset=utf-8
# strict-transport-security: max-age=15724800; includeSubDomains
```

### Kiểm tra bằng mắt thường
- **Title tab**: "Moteo Store v2.0 - DevOps Demo" (đã thay đổi)
- **URL**: `https://www.moteo.fun` (domain đúng)
- **HTTPS**: ổ khóa xanh (Let's Encrypt SSL)
- **Nội dung**: Trang web hiển thị bình thường

### 🎥 Góc quay
- **Màn hình**: Browser — `https://www.moteo.fun` với title mới
- **Thuyết minh**: "Sau khi deploy, chúng ta thấy title tab đã được cập nhật thành 'Moteo Store v2.0 - DevOps Demo'. Trang web hoạt động qua HTTPS với Let's Encrypt certificate, domain www.moteo.fun."

---

## 7. 5.6 — Monitoring and Observability Validation

### Mục tiêu
Show Grafana dashboard với real-time metrics.

### Script thực hiện

```powershell
# Bước 1: Mở Grafana
start http://localhost:3001

# Bước 2: Login
# Username: admin
# Password: Mzz7zSOwSkUei90wNHHH2TDpqkBhPHubJLMeaMht

# Bước 3: Vào Dashboard
# Home → Kubernetes / Compute Resources / Pod

# Bước 4: Chọn namespace = production
```

### Các metrics cần show

| Metric | Giá trị hiện tại | Giải thích |
|--------|-----------------|------------|
| **CPU Usage** | ~5% | Thấp vì không có traffic |
| **Memory Usage** | ~34% | Ổn định |
| **Pod Status** | 2 pods Running | Đúng với replica count |

### Custom application metrics (Optional)

```promql
# Vào Explore → Chọn Prometheus datasource

# Query 1: Tổng số HTTP requests
moteo_http_requests_total

# Query 2: Request duration histogram
moteo_http_request_duration_ms_bucket

# Query 3: Active requests hiện tại
moteo_http_active_requests
```

### 🎥 Góc quay
- **Màn hình**: Browser — Grafana dashboards
- **Thuyết minh**: "Grafana dashboard cho thấy real-time metrics của hệ thống. CPU đang ở mức thấp vì không có traffic, memory ổn định, 2 pods đang chạy. HPA sẵn sàng scale khi cần."

---

## 8. 5.7 — Failure Simulation

### Mục tiêu
Simulate pod failure và show self-healing + alerting.

### Script thực hiện

```powershell
# Bước 1: Mở terminal watch pods
kubectl get pods -n production -w

# Bước 2: Mở terminal mới, lấy tên pod đầu tiên
$POD = kubectl get pods -n production -o name | Select-Object -First 1
Write-Host "Deleting pod: $POD"

# Bước 3: Xóa pod
kubectl delete $POD -n production

# Bước 4: Quan sát terminal watch
# Output mẫu:
# devops-final-deployment-...-xxxxx   1/1   Terminating   0   5m
# devops-final-deployment-...-yyyyy   0/1   Pending       0   0s
# devops-final-deployment-...-yyyyy   0/1   ContainerCreating   0   2s
# devops-final-deployment-...-yyyyy   1/1   Running             0   5s

# Bước 5: Mở Alertmanager
start http://localhost:9093
# Show alert: HighCPUUsage hoặc Watchdog đang firing

# Bước 6: Mở Grafana
start http://localhost:3001
# Show pod status dashboard — pod mới đã Running
```

### 🎥 Góc quay
- **Màn hình**: Terminal (kubectl delete + watch) → Browser (Alertmanager) → Browser (Grafana)
- **Thuyết minh**: 
  - "Chúng tôi sẽ simulate failure bằng cách xóa một pod."
  - "Kubernetes tự động tạo pod mới để thay thế — đây là self-healing capability."
  - "Alertmanager ghi nhận sự kiện và firing alert."
  - "Grafana show pod mới đã hoạt động bình thường."

---

## 9. Bonus: Jenkins Self-Hosted CI/CD

### Mục tiêu
Show Jenkins server hoạt động.

### Script thực hiện

```powershell
# Mở Jenkins
start https://jenkins.moteo.fun
```

### Các bước trong Jenkins UI

1. **Dashboard**: Show build history
2. **Click vào pipeline gần nhất**: Show stages
3. **Stage details**:
   - Checkout: git clone repository
   - Install Dependencies: npm ci
   - Lint: npx eslint .

### 🎥 Góc quay
- **Màn hình**: Browser — Jenkins UI
- **Thuyết minh**: "Jenkins chạy trên EC2 t3.small với domain jenkins.moteo.fun (HTTPS). Pipeline tự động checkout code, cài Node.js, chạy ESLint."

---

## 10. Bonus: Automated Rollback

### Mục tiêu
Show rollback khi deployment thất bại.

### Script thực hiện

```powershell
# Bước 1: Deploy image không hợp lệ
kubectl set image deployment/devops-final-deployment -n production `
  nodejs-container=dinhquoccuong286/devops-final-app:INVALID_TAG

# Bước 2: Kiểm tra rollout status (sẽ thất bại)
kubectl rollout status deployment/devops-final-deployment -n production
# Output: error: deployment "devops-final-deployment" exceeded its progress deadline

# Bước 3: Rollback về phiên bản trước
kubectl rollout undo deployment/devops-final-deployment -n production
# Output: deployment.apps/devops-final-deployment rolled back

# Bước 4: Xác nhận rollback thành công
kubectl rollout status deployment/devops-final-deployment -n production
# Output: deployment "devops-final-deployment" successfully rolled out

kubectl get pods -n production
# Output: 2 pods Running
```

### 🎥 Góc quay
- **Màn hình**: Terminal — show rollback process
- **Thuyết minh**: "Khi deploy image không hợp lệ, rollout thất bại. Pipeline tự động chạy rollout undo để quay về phiên bản trước đó. Hệ thống vẫn hoạt động bình thường."

---

## 11. Checklist sau khi quay

### Trước khi destroy cluster

- [ ] **Scale production xuống 2 replicas** (nếu HPA đã scale lên)
  ```powershell
  kubectl scale deployment devops-final-deployment -n production --replicas=2
  ```
- [ ] **Kiểm tra tất cả pods Running**
  ```powershell
  kubectl get pods -A | findstr -v Running
  # Không được có dòng nào (chỉ header)
  ```
- [ ] **Kiểm tra website hoạt động**
  ```powershell
  curl -I https://www.moteo.fun
  # Phải trả về 200 OK
  ```
- [ ] **Chụp screenshot các figures còn thiếu** (xem SCREENSHOT_GUIDE.md)
- [ ] **Export Grafana dashboard screenshots**
- [ ] **Export GitHub Actions pipeline screenshots**

### Destroy cluster

```powershell
# Chạy destroy script
.\destroy.ps1
```

### Video đã quay đủ các phần?

- [ ] **5.1** — Source code modification (VS Code)
- [ ] **5.2** — Commit & Push (Terminal)
- [ ] **5.3** — CI Pipeline (GitHub Actions)
- [ ] **5.4** — CD Deployment (GitHub Actions + Terminal)
- [ ] **5.5** — Verify App Update (Browser — www.moteo.fun)
- [ ] **5.6** — Monitoring (Grafana)
- [ ] **5.7** — Failure Simulation (Terminal + Alertmanager + Grafana)
- [ ] **Bonus: Jenkins** (jenkins.moteo.fun)
- [ ] **Bonus: Rollback** (Terminal)

---

## 📝 Ghi chú kỹ thuật

### Grafana credentials
- **URL**: `http://localhost:3001`
- **Username**: `admin`
- **Password**: `Mzz7zSOwSkUei90wNHHH2TDpqkBhPHubJLMeaMht`

### Các port-forward cần chạy
```powershell
# Terminal A
kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3001:80

# Terminal B
kubectl port-forward -n monitoring svc/monitoring-stack-kube-prom-alertmanager 9093:9093
```

### Lưu ý
- Quay video ở **1080p** hoặc cao hơn
- Đảm bảo **âm thanh rõ** (thuyết minh)
- **Không pause** giữa các bước — quay liên tục
- Nếu cần, có thể quay từng phần riêng rồi ghép lại
- **Không dùng** mock data hoặc pre-recorded pipeline
