# 🔦 GUIDING LIGHT — Hướng dẫn Khôi phục Toàn bộ Hệ thống

> File này giúp bạn khôi phục nguyên trạng hệ thống DevOps Final Project
> từ khi `terraform apply` đến khi `terraform destroy`.
> Mỗi khi bật lại hệ thống, chỉ cần làm theo từng bước dưới đây.

---

## ⚡ PHẦN 1: Khởi tạo hạ tầng (Terraform)

### Bước 1.1: Khởi tạo Terraform
```bash
cd infrastructure
terraform init
terraform apply -auto-approve
```
> ⏱️ Chờ khoảng **15–20 phút** để AWS tạo VPC + EKS + Jenkins EC2.

### Bước 1.2: Ghi lại thông tin quan trọng
Sau khi apply xong, Terraform sẽ hiện các output:
```
jenkins_public_ip       = "x.x.x.x"        ← IP Jenkins (dùng cho DNS)
jenkins_ssh             = "ssh ubuntu@..."  ← Lệnh SSH vào Jenkins
jenkins_url             = "https://jenkins.moteo.fun"
s3_uploads_bucket_name  = "devops-final-uploads-dqc28664"  ← S3 bucket cho image uploads
```
**Lưu lại IP này!** Bạn sẽ cần nó cho bước DNS.
> S3 bucket đã được cấu hình tên cố định, không cần thay đổi gì trong `deployment.yaml`.

### Bước 1.3: Kết nối kubectl vào EKS Cluster mới
```bash
aws eks update-kubeconfig --region ap-southeast-2 --name devops-final-cluster
```
Kiểm tra kết nối:
```bash
kubectl get nodes
# Phải thấy 2 nodes ở trạng thái Ready
```

---

## 🌐 PHẦN 2: Cài đặt Ingress NGINX (HTTPS Controller)

### Bước 2.1: Thêm Helm repo và cài đặt
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
```

### Bước 2.2: Lấy địa chỉ Load Balancer mới
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller
```
Copy giá trị cột **EXTERNAL-IP** (dạng `xxxxx.elb.ap-southeast-2.amazonaws.com`).
> ⚠️ Nếu thấy `<pending>`, đợi 1-2 phút rồi chạy lại.

---

## 🔒 PHẦN 3: Cài đặt Cert-Manager (SSL/HTTPS tự động)

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set crds.enabled=true
```

---

## 📊 PHẦN 4: Cài đặt Metrics & Monitoring

### 4.1: Cài đặt Kubernetes Metrics Server (sửa lỗi HPA báo `<unknown>`)
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### 4.2: Cài đặt Prometheus + Grafana
```bash
helm install monitoring-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace
```

### Xem mật khẩu Grafana:
```bash
kubectl --namespace monitoring get secrets monitoring-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
- **Username:** `admin`
- **Password:** (lệnh trên sẽ hiện)

### Mở Grafana dashboard:
```bash
kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80
```
Truy cập: `http://localhost:3000`

---

## 📋 PHẦN 5: Apply các file K8s (Ingress SSL + Alerting Rules)

```bash
kubectl apply -f kubernetes/ingress-ssl.yaml
kubectl apply -f kubernetes/alerting-rules.yaml
```
Kiểm tra chứng chỉ SSL đã được cấp:
```bash
kubectl get certificate -n production
# Chờ 1-2 phút, trạng thái phải là "True" ở cột READY
```

---

## 🌍 PHẦN 6: Cập nhật DNS trên Hostinger

### 6.1: Subdomain `www` → EKS App
1. Đăng nhập [Hostinger](https://hpanel.hostinger.com/)
2. Vào **Domains** → `moteo.fun` → **DNS / Nameservers** → **DNS Records**
3. **Sửa** (hoặc tạo mới) bản ghi CNAME cho `www`:
   | Type | Name | Target (Points to) | TTL |
   |------|------|-------------------|-----|
   | **CNAME** | `www` | `<EXTERNAL-IP từ Bước 2.2>` | 300 |

### 6.2: Subdomain `jenkins` → Jenkins EC2
4. **Thêm** bản ghi A mới:
   | Type | Name | Target (Points to) | TTL |
   |------|------|-------------------|-----|
   | **A** | `jenkins` | `<IP từ Bước 1.2>` | 300 |

> ⏱️ DNS cần 1–5 phút để cập nhật.

---

## 🔧 PHẦN 7: Setup Jenkins (Chỉ cần làm lần đầu tiên)

### 7.1: SSH vào Jenkins EC2
```bash
cd infrastructure
ssh -i jenkins-key.pem ubuntu@<IP_JENKINS>
# Gõ "yes" nếu được hỏi
```

### 7.2: Lấy mật khẩu admin Jenkins
```bash
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### 7.3: Cài SSL cho Jenkins
```bash
sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun
```

### 7.4: Truy cập Jenkins
- URL: **https://jenkins.moteo.fun**
- Chọn **Install suggested plugins**
- Tạo Admin User
- Cài thêm plugin: **Docker Pipeline** (Manage Jenkins → Plugins → Available)

### 7.5: Tạo Pipeline Job
1. Dashboard → **New Item** → tên `DevOps-Final-CI` → chọn **Pipeline** → OK
2. Kéo xuống phần **Pipeline**, chọn `Pipeline script from SCM`
3. SCM: `Git`
4. Repository URL: `https://github.com/DinhQuocCuong28664/DevOps_Final_Project.git`
5. Branch: `*/main`
6. **Save** → **Build Now**

---

## ✅ PHẦN 8: Kiểm tra tất cả đã hoạt động

```bash
# 1. Kiểm tra pods production
kubectl get pods -n production
# Phải thấy 2 pods Running

# 2. Kiểm tra pods staging
kubectl get pods -n staging
# Phải thấy 1 pod Running

# 3. Kiểm tra services
kubectl get svc -A
# Phải thấy ClusterIP ở production + LoadBalancer ở ingress-nginx

# 4. Kiểm tra SSL certificate
kubectl get certificate -n production
# READY phải là True

# 5. Kiểm tra alerting rules
kubectl get prometheusrule -n monitoring
# Phải thấy devops-final-alerts

# 6. Kiểm tra HPA
kubectl get hpa -n production
# Phải thấy 2-5 pods, CPU/RAM targets
```

### Truy cập test:
- 🌐 App: **https://www.moteo.fun**
- 🔧 Jenkins: **https://jenkins.moteo.fun**
- 📊 Grafana: `kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80` → `http://localhost:3000`

---

## 🔴 PHẦN 9: Dọn dẹp tài nguyên (Destroy)

> ⚠️ **QUAN TRỌNG:** Phải xóa Load Balancer TRƯỚC khi destroy Terraform,
> nếu không VPC sẽ bị kẹt vì ENI (Network Interface) còn tồn tại.

### Bước 9.1: Xóa Helm releases (để giải phóng LoadBalancer)
```bash
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall cert-manager -n cert-manager
helm uninstall monitoring-stack -n monitoring
```

### Bước 9.2: Xóa các tài nguyên K8s trong namespaces
```bash
kubectl delete -f kubernetes/ingress-ssl.yaml --ignore-not-found
kubectl delete -f kubernetes/alerting-rules.yaml --ignore-not-found
kubectl delete -f kubernetes/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/service.yaml --ignore-not-found
kubectl delete -f kubernetes/hpa.yaml --ignore-not-found
kubectl delete -f kubernetes/staging/deployment.yaml --ignore-not-found
kubectl delete -f kubernetes/staging/service.yaml --ignore-not-found
```

### Bước 9.3: Xóa namespaces
```bash
kubectl delete namespace ingress-nginx --ignore-not-found
kubectl delete namespace cert-manager --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found
kubectl delete namespace staging --ignore-not-found
kubectl delete namespace production --ignore-not-found
```

### Bước 9.4: Chờ tất cả LoadBalancer bị xóa
```bash
kubectl get svc -A | grep LoadBalancer
# Phải trả về KHÔNG CÒN service nào type LoadBalancer (trừ kubernetes)
```
> Nếu vẫn còn, đợi 1-2 phút rồi kiểm tra lại.

### Bước 9.5: Terraform Destroy
```bash
cd infrastructure
terraform destroy -auto-approve
```
> ⏱️ Chờ khoảng **10–15 phút** để AWS xóa toàn bộ (bao gồm cả S3 bucket — tự động xóa ảnh nhờ `force_destroy`).

### Bước 9.6: Xóa DNS trên Hostinger
- Vào Hostinger → DNS Records → **Xóa** bản ghi CNAME `www` và A `jenkins`.

---

## 📝 TÓM TẮT NHANH (Cheat Sheet)

### Bật hệ thống (Apply):
```bash
cd infrastructure
terraform init && terraform apply -auto-approve          # 1. Tạo hạ tầng (~15 phút)
aws eks update-kubeconfig --region ap-southeast-2 --name devops-final-cluster  # 2. Kết nối kubectl
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace  # 3. Ingress
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --set crds.enabled=true  # 4. SSL
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml # 4.5. HPA Metrics
helm install monitoring-stack prometheus-community/kube-prometheus-stack -n monitoring --create-namespace  # 5. Monitoring
kubectl apply -f kubernetes/ingress-ssl.yaml             # 6. Apply SSL config
kubectl apply -f kubernetes/alerting-rules.yaml          # 7. Apply alert rules
# 8. Cập nhật DNS Hostinger (CNAME www + A jenkins)
# 9. SSH vào Jenkins → certbot → setup
```

### Tắt hệ thống (Destroy):
```bash
helm uninstall ingress-nginx -n ingress-nginx            # 1. Gỡ Ingress
helm uninstall cert-manager -n cert-manager              # 2. Gỡ SSL
helm uninstall monitoring-stack -n monitoring             # 3. Gỡ Monitoring
kubectl delete ns ingress-nginx cert-manager monitoring staging production --ignore-not-found  # 4. Xóa NS
# Đợi 1-2 phút cho LB xóa xong
cd infrastructure
terraform destroy -auto-approve                           # 5. Xóa hạ tầng (~10 phút)
# 6. Xóa DNS Hostinger
```
