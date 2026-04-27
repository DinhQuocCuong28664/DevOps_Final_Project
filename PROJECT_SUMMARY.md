# 🚀 DevOps Final Project — Tổng kết Quá trình Xây dựng

> **Dự án:** Triển khai ứng dụng Node.js lên Amazon EKS với CI/CD Pipeline tự động hóa hoàn toàn  
> **Tên miền:** [https://www.moteo.fun](https://www.moteo.fun)  
> **Kiến trúc:** Tier 5 (Cao cấp nhất)

---

## 1. 🏗️ Hạ tầng dưới dạng Mã (Infrastructure as Code - IaC)

**Thành quả:** Viết thành công 3 file Terraform (`provider.tf`, `vpc.tf`, `eks.tf`) để tự động hóa việc xây dựng mạng lưới và cụm Kubernetes (Amazon EKS) trên AWS.

**Điểm nhấn:**
- Thiết lập kiến trúc **Tier 5** (Cao cấp nhất) — đi thẳng vào Kubernetes thay vì triển khai thủ công.
- Giấu kín các file chứa chìa khóa bảo mật (Access Keys `.csv`) và trạng thái hạ tầng (`terraform.tfstate`) khỏi GitHub thông qua `.gitignore`.
- Tạo IAM User riêng (`devops-admin`) với quyền vừa đủ thay vì dùng tài khoản Root nguy hiểm.

| File | Vai trò |
|------|---------|
| `provider.tf` | Khai báo Region Sydney (`ap-southeast-2`) |
| `vpc.tf` | VPC, Public/Private Subnets, NAT Gateway |
| `eks.tf` | EKS Cluster (K8s 1.30), 2x Worker Nodes `t3.medium` |

---

## 2. 🐳 DevSecOps & Tối ưu hóa Container

**Thành quả:** Đóng gói ứng dụng Node.js bằng Dockerfile chuẩn doanh nghiệp.

**Điểm nhấn:**
- Dùng kỹ thuật **Multi-stage Build** để giảm kích thước Image tối đa — chỉ giữ lại production dependencies.
- Cấu hình chạy ứng dụng bằng **User thường** (`appuser`) thay vì Root để chống hacker leo quyền.
- Tự tay fix lỗi **CrashLoopBackOff** do phân quyền thư mục (`EACCES: permission denied, mkdir '/app/public/uploads'`) bằng cách tạo sẵn thư mục và `chown` trước khi chuyển sang non-root user.

---

## 3. 🔄 Đường ống CI/CD Tự động hóa hoàn toàn

**Thành quả:** Xây dựng file `ci.yml` trên GitHub Actions tự động hóa 100% quy trình từ code đến production.

**Luồng Pipeline:**
```
Code Push → Checkout → Node.js Setup → npm ci → Trivy Scan 🛡️ → Docker Build & Push → Deploy to EKS 🚀
```

**Điểm nhấn:**
- Vượt qua bài test bảo mật khắt khe. Khi công cụ **Trivy** phát hiện **10 lỗi HIGH** trong các thư viện (`multer`, `minimatch`, `nodemon`), không chọn cách bỏ qua mà dũng cảm cập nhật thư viện lên phiên bản an toàn để vá lỗi, giúp đường ống xanh trở lại.
- Docker Image luôn được gắn **Tag bằng mã SHA** của Git commit thay vì dùng tag `latest` nguy hiểm — đảm bảo truy vết chính xác phiên bản đang chạy.

---

## 4. ☸️ Triển khai lên Production (Continuous Delivery)

**Thành quả:** Viết các bản vẽ Kubernetes (`deployment.yaml`, `service.yaml`) và giao cho GitHub Actions tự động kết nối với AWS để cập nhật ứng dụng mỗi khi có code mới.

| File | Vai trò |
|------|---------|
| `deployment.yaml` | 2 replicas, resource limits, image tag placeholder cho CD |
| `service.yaml` | **ClusterIP**, port 80 → container port 3000 (internal, traffic vào qua Ingress) |

**Cơ chế hoạt động:** CD pipeline dùng `sed` để thay thế `IMAGE_TAG_PLACEHOLDER` bằng commit SHA mới nhất, sau đó `kubectl apply` lên cụm EKS.

---

## 5. 🔒 Tên miền & Bảo mật HTTPS (Điểm tuyệt đối)

**Thành quả:** Tạm biệt cái link AWS dài ngoằng! Ứng dụng đã chạy mượt mà trên tên miền chính chủ **[www.moteo.fun](https://www.moteo.fun)**.

**Điểm nhấn:**
- Cài đặt thành công **NGINX Ingress Controller** làm cổng ra vào duy nhất cho cụm Kubernetes.
- Triển khai **Cert-Manager** + **Let's Encrypt** tự động xin và gia hạn chứng chỉ SSL/TLS.
- Website hiển thị ổ khóa xanh lá 🟢 (HTTPS) — đạt chuẩn bảo mật cho production.

| Thành phần | Phiên bản |
|------------|-----------|
| Ingress NGINX Controller | v1.10.0 |
| Cert-Manager | v1.14.4 |
| Let's Encrypt | ACME v02 (Production) |

---

## 📁 Cấu trúc Dự án

```
DevOps_Final/
├── .github/workflows/
│   └── ci.yml                  # CI/CD Pipeline (GitHub Actions)
├── application/
│   ├── Dockerfile              # Multi-stage build, non-root user
│   ├── .dockerignore           # Giảm kích thước build context
│   ├── .gitignore              # Bỏ qua node_modules, .env, logs
│   ├── main.js                 # Entry point (Express.js)
│   ├── package.json            # Dependencies (0 vulnerabilities ✅)
│   ├── controllers/            # Business logic
│   ├── models/                 # Data models
│   ├── routes/                 # API routes
│   ├── services/               # Service layer
│   ├── validators/             # Input validation
│   ├── views/                  # EJS templates
│   └── public/                 # Static assets
├── infrastructure/
│   ├── provider.tf             # AWS Provider (Sydney)
│   ├── vpc.tf                  # VPC, Subnets, NAT Gateway
│   ├── eks.tf                  # EKS Cluster + Worker Nodes
│   ├── s3.tf                   # S3 bucket cho image uploads + IAM policy
│   ├── jenkins.tf              # Jenkins EC2 + Security Group + EIP
│   └── workstation.tf          # DevOps Workstation EC2 + IAM Instance Profile
├── kubernetes/
│   ├── deployment.yaml         # 2 replicas, resource limits
│   ├── service.yaml            # LoadBalancer Service
│   └── ingress-ssl.yaml        # Ingress + TLS (Let's Encrypt)
├── .gitignore                  # Bỏ qua .terraform, tfstate, .csv
├── setup.sh                    # Cài tools tự động trên EC2 mới (AWS CLI, Terraform, kubectl, Helm, Docker, Node.js)
└── PROJECT_SUMMARY.md          # File này
```
