# 📋 FINAL EXAM PROJECT SPECIFICATION
## Production-Grade CI/CD System

| | |
|---|---|
| **Course** | Software Deployment, Operations & Maintenance |
| **Assessment Type** | Final Exam Project (50% of total course grade) |
| **Duration** | 6 weeks |
| **Team Size** | 2–3 students |

---

## 📊 TIẾN ĐỘ THỰC HIỆN CỦA NHÓM

> **Kiến trúc đã chọn:** Tier 5 – Expert (Amazon EKS) ⭐
> **Tên miền:** [https://www.moteo.fun](https://www.moteo.fun)
> **Repository:** [DevOps_Final_Project](https://github.com/DinhQuocCuong28664/DevOps_Final_Project)

| Hạng mục | Yêu cầu | Trạng thái | Ghi chú |
|----------|---------|-----------|---------|
| IaC (Terraform) | Bắt buộc ⭐ | ✅ Done | `provider.tf`, `vpc.tf`, `eks.tf` |
| Code Linting | Bắt buộc | ✅ Done | ESLint v9 — 0 errors |
| Dependency Caching | Bắt buộc | ✅ Done | npm cache trong CI |
| Security Scanning | Bắt buộc | ✅ Done | Trivy — fail on CRITICAL/HIGH |
| Docker Build + Push | Bắt buộc | ✅ Done | Tag = commit SHA, push Docker Hub |
| CD Deploy to EKS | Bắt buộc | ✅ Done | `kubectl apply` tự động |
| Domain + HTTPS | Bắt buộc | ✅ Done | `www.moteo.fun` + Let's Encrypt |
| K8s Deployments/Services | Tier 5 | ✅ Done | 2 replicas + LoadBalancer |
| Ingress Controller | Tier 5 | ✅ Done | NGINX v1.10.0 |
| HPA Autoscaling | Tier 5 (khuyến khích) | ✅ Done | 2→5 pods, CPU 60%, RAM 70% |
| Self-healing | Tier 5 | ✅ Done | `kubectl delete pod` → pod tự tạo lại |
| Prometheus Metrics | Bắt buộc | ✅ Done | kube-prometheus-stack |
| Grafana Dashboards | Bắt buộc | ✅ Done | CPU, RAM, pod status |
| Alerting (Alertmanager) | Khuyến khích | ✅ Done | 4 rules: PodCrash, CPU, RAM, Replicas |
| Failure Simulation | Demo bắt buộc | ✅ Done | Kill pod → self-healing verified |

---

## SECTION I. INTRODUCTION AND PURPOSE

The Final Exam Project requires students to design, implement, and demonstrate a **production-grade software delivery system**, comparable to those operated by professional DevOps teams in real-world enterprise environments. The focus extends beyond application deployment to encompass the entire lifecycle of software delivery, including:

- Infrastructure provisioning
- Continuous integration
- Continuous delivery
- Security integration
- System observability

Students are expected to evolve the web application used in the mid-term project or replace it with an equivalent application of comparable complexity. While application functionality itself is not the primary assessment target, the system must be sufficiently realistic to support continuous deployment, monitoring, and scaling.

This project adopts a **progressive difficulty model**. Teams may select different architectural approaches, each associated with a different maximum score for orchestration complexity.

---

## SECTION II. BACKGROUND SCENARIO

> **"Startup X"** is entering a rapid growth phase and requires its DevOps team to standardize and harden the entire deployment process according to production standards.

The current system lacks several critical enterprise-level capabilities:

- ✅ End-to-end automation from source code to production
- ✅ Integrated security throughout the deployment lifecycle (DevSecOps)
- ✅ Scalability to accommodate increasing user demand
- ✅ Observability and early failure detection

Students assume the role of **DevOps Engineers** tasked with designing and implementing this production-ready deployment pipeline, infrastructure, and monitoring stack.

---

## SECTION III. ARCHITECTURE TIERS AND DEPLOYMENT MODELS

Each team must select **one deployment architecture tier** that reflects both their technical ambition and their ability to operate the system reliably.

### Tier 1 – Basic: Single-Server Non-Containerized Deployment

Application is deployed directly on the OS using process managers such as `PM2` or `systemd`. This tier:
- ❌ Does not support horizontal scaling or auto-scaling
- ❌ No container-based isolation
- ⚠️ **Strongly discouraged** — caps maximum architecture score

### Tier 2 – Standard: Single-Server Containerized Deployment

Multi-container application on a single Linux server using **Docker Compose**.
- Must implement reverse proxy container, persistent volumes
- Container-level horizontal scaling expected

### Tier 3 – Advanced: Multi-Server Architecture with Centralized Load Balancing

Application deployed across **multiple Ubuntu servers** without container orchestration.
- **Preferred:** Managed cloud load balancer (AWS ALB, GCP LB, Azure LB)
- **Alternative:** Nginx or HAProxy (lower-priority)
- Must demonstrate horizontal scaling across servers

### Tier 4 – Advanced: Docker Swarm–Based Orchestration

Multi-node **Docker Swarm** cluster with:
- Declarative service definitions
- Container scheduling across nodes
- Service replication and basic fault tolerance

### Tier 5 – Expert: Kubernetes-Based Architecture ⭐ ← NHÓM CHỌN TIER NÀY

> **Highest potential score** for architecture and orchestration.

Production-grade container orchestration using Kubernetes (upstream, K3s, or managed: **EKS**, GKE, AKS).
- ✅ Must demonstrate: Deployments, Services, ConfigMaps, Secrets
- ✅ **Ingress Controller** required for external access — *NGINX Ingress v1.10.0*
- ✅ **Self-healing** behaviour expected — *Đã demo: delete pod → auto recreate*
- ✅ **HPA** (Horizontal Pod Autoscaling) strongly encouraged — *2→5 pods, CPU 60%, RAM 70%*

---

## SECTION IV. TECHNICAL SPECIFICATIONS

### 4.1 Infrastructure Provisioning and Environment Setup

All deployments must be hosted on a **real cloud provider** (AWS, Azure, GCP, Oracle Cloud, DigitalOcean).

#### A. Infrastructure as Code (IaC) — Recommended ⭐ ← ĐÃ THỰC HIỆN

Using tools such as **Terraform** + **Ansible**:
- ✅ Provisioning compute resources and networking — *VPC, Subnets, NAT Gateway*
- ✅ Defining security groups / firewall rules — *EKS Security Groups*
- ✅ Configuring storage resources
- ✅ Installing required system dependencies — *EKS v1.30, 2x t3.medium worker nodes*
- ✅ All definitions must be **idempotent** — *Terraform state management*

#### B. Manual Infrastructure Provisioning

Acceptable but limits maximum score. Minimum requirements regardless of method:
- ✅ Publicly accessible cloud server — *AWS ap-southeast-2 (Sydney)*
- ✅ Registered domain name resolving to the system — *www.moteo.fun*
- ✅ HTTPS configured (Let's Encrypt or equivalent) — *Cert-Manager v1.14.4 + Let's Encrypt ACME v02*

---

### 4.2 CI/CD Pipeline

#### 4.2.1 Continuous Integration (CI) ← TẤT CẢ ĐÃ HOÀN THÀNH

| Step | Requirement | Trạng thái | Công cụ |
|------|------------|-----------|---------|
| **Code Linting** | Static analysis tools | ✅ Done | ESLint v9 (0 errors, 7 warnings) |
| **Dependency Caching** | Cache `node_modules` | ✅ Done | GitHub Actions npm cache |
| **Build Artifacts** | Reproducible Docker image | ✅ Done | Multi-stage build, Node 18-alpine |
| **Security Scanning** | Fail on CRITICAL/HIGH | ✅ Done | Trivy — 0 vulnerabilities |
| **Image Build & Push** | Explicit version tags | ✅ Done | Docker Hub, tag = Git SHA |

#### 4.2.2 Continuous Delivery (CD) ← ĐÃ HOÀN THÀNH

At minimum, the CD pipeline must:
- ✅ Retrieve correct versioned artifact/container image — *sed thay IMAGE_TAG_PLACEHOLDER*
- ✅ Update deployment configurations — *kubectl apply deployment + service + hpa*
- ✅ Deploy to production automatically — *Sau khi CI pass*
- ✅ Restart/update services in controlled manner — *Rolling update (K8s default)*

For staging + production environments:
- Separate deployment targets
- Manual approval gate
- Documented deployment strategy (recreate, rolling update)

---

### 4.3 Architecture-Specific Deployment Requirements

| Tier | Requirements | Nhóm |
|------|-------------|------|
| **Tier 1** | `systemd` or `PM2`, auto-restart after reboot | |
| **Tier 2** | Docker Compose, persistent volumes, service scaling | |
| **Tier 3** | Cloud managed LB preferred, horizontal scaling | |
| **Tier 4** | Swarm cluster, replicated services, cluster scheduling | |
| **Tier 5** | K8s Deployments, Services, Ingress. **HPA & self-healing encouraged** | ✅ **CHỌN** |

---

### 4.4 Monitoring and Observability ← TẤT CẢ ĐÃ HOÀN THÀNH

**Minimum Requirements:**
- ✅ Metrics collection (Prometheus or equivalent) — *kube-prometheus-stack via Helm*
- ✅ Grafana dashboards: CPU, memory, service/pod status — *Built-in K8s dashboards*

**Advanced (Encouraged):**
- ✅ Alerting via Alertmanager — *4 custom rules: PodCrashLooping, HighCPU, HighRAM, ReplicasMismatch*
- Centralized logging (Loki or ELK)
- Custom application-level metrics (request rates, error counts)

> ✅ Monitoring components have been **actively demonstrated** with live Grafana dashboards.

---

### 4.5 Documentation and Evidence

All implementations must be:
- ✅ Fully documented in the technical report
- ✅ Supported by screenshots, logs, or configuration excerpts
- ✅ Demonstrated in video and live presentation

---

## SECTION V. MANDATORY DEMONSTRATION SCENARIO

### 5.1 Source Code Modification ✅
Make a visible, meaningful change to application source code (UI text, feature, config). Must **not** be pre-staged.

### 5.2 Commit and Push ✅
- ✅ Clear commit message
- ✅ Correct target branch triggering pipeline
- ✅ Successful sync with remote repository

### 5.3 CI Pipeline Execution ✅
Show execution and outcome of **each CI stage**:
- ✅ Code linting and quality checks — *ESLint v9*
- ✅ Dependency restoration and caching — *npm cache*
- ✅ Build stage — reproducible artifact — *Docker multi-stage build*
- ✅ Security scanning — vulnerability detection — *Trivy*
- ✅ Container image build and registry push — *Docker Hub + SHA tag*

### 5.4 CD Deployment ✅
- ✅ Retrieval of correct artifact version
- ✅ Updated deployment configurations
- ✅ Deployment execution appropriate to tier
- ✅ Controlled service restart / rolling update

### 5.5 Verification of Application Update ✅
- ✅ Access via public domain name — *www.moteo.fun*
- ✅ Visible change is present
- ✅ System accessible via **HTTPS only**
- ✅ Correct application behaviour

### 5.6 Monitoring and Observability Validation ✅
- ✅ Open Grafana dashboard
- ✅ Show real-time metrics (CPU, memory, pod status)
- ✅ Explain how metrics reflect current system state

### 5.7 Failure Simulation ✅
Simulate failure appropriate to tier:
- ✅ Terminate a pod — *kubectl delete pod*

Results demonstrated:
- ✅ System responds to failure — *K8s immediately creates replacement pod*
- ✅ Services **recover automatically** — *2/2 pods restored within 5 seconds*
- ✅ Failure reflected in monitoring dashboards — *Alertmanager rules trigger on ReplicasMismatch*

---

## SECTION VI. SUBMISSION DELIVERABLES

### 6.1 Project Repository and Technical Artefacts
- ✅ Complete application source code
- ✅ Infrastructure provisioning artefacts (Terraform) — `provider.tf`, `vpc.tf`, `eks.tf`
- ✅ CI/CD pipeline configuration (GitHub Actions) — `ci.yml`
- ✅ Deployment artefacts — `Dockerfile`, `deployment.yaml`, `service.yaml`, `hpa.yaml`, `ingress-ssl.yaml`
- ✅ Monitoring configuration — `alerting-rules.yaml`, kube-prometheus-stack (Helm)
- ✅ **No hard-coded secrets** — `.gitignore` chặn `*.tfstate`, `*.csv`, `.env`

### 6.2 Technical Report (PDF)
Five required chapters:
1. Overview & System Architecture
2. Infrastructure Provisioning
3. CI/CD Pipeline Design
4. Deployment & Orchestration
5. Monitoring, Observability & Lessons Learned

### 6.3 Video Demonstration
Full end-to-end demo following Section V scenario.

### 6.4 Production Website URL
- ✅ Public domain URL — *https://www.moteo.fun*
- ✅ Valid TLS certificate (HTTPS) — *Let's Encrypt via Cert-Manager*
- ✅ System remains accessible during grading

### 6.5 Supporting Links
- ✅ Source code repository — *github.com/DinhQuocCuong28664/DevOps_Final_Project*
- ✅ Container registry — *hub.docker.com/r/dinhquoccuong286/devops-final-app*
- Monitoring dashboards (if externally accessible)

---

## SECTION VII. EXTRA CREDIT (Bonus)

Each bonus: **0.25 – 0.5 points**. Must be functional, demonstrated, and documented.

### 7.1 Self-Hosted CI/CD Infrastructure
Deploy own GitLab/Jenkins on separate machine with custom domain + HTTPS.
> ⏭️ Không thực hiện

### 7.2 Multi-Environment Deployment with Approval Gates
Staging + Production with manual approval step.
> ⏭️ Không thực hiện

### 7.3 Advanced Deployment Strategies
Rolling updates, blue–green deployment, or canary releases.
> ✅ **Rolling update** — Kubernetes mặc định sử dụng `RollingUpdate` strategy trong Deployment

### 7.4 Automated Rollback Mechanisms
Triggered by failed health checks, deployment errors, or pipeline failures.
> ⏭️ Không thực hiện

### 7.5 Bonus Award Conditions
- Must reach **competent implementation level**
- Incomplete/unstable features = **no bonus**
- Cannot compensate for missing core requirements

---

## 📁 CẤU TRÚC DỰ ÁN

```
DevOps_Final/
├── .github/workflows/
│   └── ci.yml                      # CI/CD Pipeline (GitHub Actions)
├── application/
│   ├── Dockerfile                  # Multi-stage build, non-root user (appuser)
│   ├── .dockerignore               # Giảm kích thước build context
│   ├── .gitignore                  # Bỏ qua node_modules, .env, logs
│   ├── eslint.config.mjs           # ESLint v9 config (Code Linting)
│   ├── main.js                     # Entry point (Express.js)
│   ├── package.json                # Dependencies (0 vulnerabilities ✅)
│   ├── controllers/                # Business logic
│   ├── models/                     # Data models
│   ├── routes/                     # API routes (multer v2.1.1)
│   ├── services/                   # Service layer
│   ├── validators/                 # Input validation
│   ├── views/                      # EJS templates
│   └── public/                     # Static assets + uploads/
├── infrastructure/
│   ├── provider.tf                 # AWS Provider (Sydney ap-southeast-2)
│   ├── vpc.tf                      # VPC, Subnets, NAT Gateway
│   └── eks.tf                      # EKS Cluster v1.30 + 2x Worker Nodes t3.medium
├── kubernetes/
│   ├── deployment.yaml             # 2 replicas, resource limits, image tag placeholder
│   ├── service.yaml                # LoadBalancer → port 3000
│   ├── hpa.yaml                    # HPA: 2→5 pods, CPU 60%, RAM 70%
│   ├── ingress-ssl.yaml            # Ingress NGINX + TLS (Let's Encrypt)
│   └── alerting-rules.yaml         # Alertmanager: 4 rules (crash, CPU, RAM, replicas)
├── .gitignore                      # Chặn *.tfstate, *.csv, .terraform/
├── Final_Project.md                # Rubric + Tiến độ (File này)
└── PROJECT_SUMMARY.md              # Tổng kết dự án
```

---

## 👥 THÀNH VIÊN NHÓM

| Tên | GitHub | Email | Vai trò |
|-----|--------|-------|---------|
| 523H0008 | DinhQuocCuong28664 | 532H0008@student.tdtu.edu.vn | Owner repo |
| NQT | nguyenquangtruong08112005 | nguyenquangtruong08112005@gmail.com | DevOps |
| PhamMHao | PhamMHao | pham.m.hao05@gmail.com | DevOps |