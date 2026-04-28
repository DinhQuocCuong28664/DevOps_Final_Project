# DevOps Final Project — Build Summary

> **Project:** Deploy a Node.js application to Amazon EKS with a fully automated CI/CD Pipeline
> **Domain:** [https://www.moteo.fun](https://www.moteo.fun)
> **Jenkins:** [https://jenkins.moteo.fun](https://jenkins.moteo.fun)
> **Architecture:** Tier 5 (Highest level — Amazon EKS)

---

## 1. Infrastructure as Code (IaC)

**Achievement:** Wrote Terraform files to automate the provisioning of the entire AWS infrastructure.

**Highlights:**
- Implemented **Tier 5** architecture — deploying directly to Kubernetes (EKS) instead of manual provisioning.
- Excluded sensitive files (Access Keys `.csv`, `.pem`, `terraform.tfstate`) from GitHub via `.gitignore`.
- Created a dedicated IAM User (`devops-admin`) with least-privilege permissions.
- Added **EBS CSI Driver** as a cluster addon + `AmazonEBSCSIDriverPolicy` to node group — enables PersistentVolumeClaims automatically.
- Added `lifecycle { create_before_destroy = true }` to Security Groups to prevent Terraform deadlock on re-apply.

| File | Role |
|------|------|
| `provider.tf` | Declares the Sydney region (`ap-southeast-2`) |
| `vpc.tf` | VPC, Public/Private Subnets, NAT Gateway |
| `eks.tf` | EKS Cluster (K8s 1.30), 2x Worker Nodes `t3.medium`, EBS CSI addon |
| `s3.tf` | S3 bucket for image uploads + IAM policy |
| `jenkins.tf` | Jenkins EC2 `t3.small` + Security Group + Elastic IP + SSH Key |
| `workstation.tf` | DevOps Workstation EC2 + IAM Instance Profile |

---

## 2. DevSecOps and Container Optimization

**Achievement:** Packaged the Node.js application using an enterprise-grade Dockerfile.

**Highlights:**
- Used **Multi-stage Build** to minimize image size — keeping only production dependencies.
- Configured the app to run as a **non-root user** (`appuser`) to prevent privilege escalation.
- **Trivy** security scan integrated in CI — fails pipeline on CRITICAL/HIGH vulnerabilities.
- **ESLint v9** code quality check integrated in CI — 0 errors.

---

## 3. Fully Automated CI/CD Pipeline

**Achievement:** 3-job GitHub Actions pipeline (CI → Staging → Production) + Self-hosted Jenkins (bonus).

**GitHub Actions pipeline flow:**
```
Push to main
  -> [Job 1] CI: Checkout -> Node.js Setup -> npm ci (cached) -> ESLint -> Trivy -> Docker Build & Push
  -> [Job 2] Staging: kubectl apply -f kubernetes/staging/ (auto)
  -> [Job 3] Production: Manual Approve -> kubectl apply -> Health Check -> Auto Rollback if fail
```

**Jenkins pipeline (bonus — https://jenkins.moteo.fun):**
```
Checkout -> npm ci -> ESLint lint
```

**Highlights:**
- Docker images tagged with **Git commit SHA** (never `latest`) — precise version traceability.
- **Staging** uses production MongoDB via cross-namespace DNS (`mongodb-service.production.svc.cluster.local`).
- **Automated Rollback:** `kubectl rollout undo` triggered automatically if production health check fails.
- **Health check fix:** `/health` returns 200 when app uses in-memory fallback — prevents false liveness probe failures.

---

## 4. Production Deployment (Continuous Delivery)

**Achievement:** Full Kubernetes deployment with MongoDB persistence, HPA autoscaling, and self-healing.

| File | Role |
|------|------|
| `deployment.yaml` | 2 replicas, RollingUpdate (maxUnavailable=0), readinessProbe /health |
| `service.yaml` | ClusterIP, port 80 → container port 3000 |
| `hpa.yaml` | HPA: 2→5 pods, CPU threshold 60%, RAM threshold 70% |
| `mongodb-pvc.yaml` | PersistentVolumeClaim 1Gi (StorageClass: gp2) |
| `mongodb-deployment.yaml` | MongoDB 7 pod |
| `mongodb-service.yaml` | ClusterIP exposing port 27017 |
| `staging/deployment.yaml` | 1 replica, connects to production MongoDB cross-namespace |
| `staging/service.yaml` | ClusterIP for staging |

---

## 5. Custom Domain and HTTPS Security

**Achievement:** Application on **[www.moteo.fun](https://www.moteo.fun)** + Jenkins on **[jenkins.moteo.fun](https://jenkins.moteo.fun)** with full HTTPS.

**Highlights:**
- **NGINX Ingress Controller** as the single entry point for the Kubernetes cluster.
- **Cert-Manager** + **Let's Encrypt** for automatic SSL/TLS certificate provisioning and renewal.
- **Certbot** + **Nginx** reverse proxy on Jenkins EC2 for Jenkins HTTPS.

| Component | Version |
|-----------|---------|
| Ingress NGINX Controller | v1.10.0 |
| Cert-Manager | v1.14.4 |
| Let's Encrypt | ACME v02 (Production) |

---

## 6. Monitoring and Observability

**Achievement:** Full observability stack with metrics, dashboards, alerting, and centralized logging.

| Component | Role |
|-----------|------|
| `kube-prometheus-stack` | Prometheus + Grafana + Alertmanager (via Helm) |
| `loki-stack` | Loki + Promtail centralized logging (via Helm) |
| `metrics.js` | Custom app-level metrics (prom-client): HTTP rate, latency, CRUD ops, S3 uploads |
| `prometheus-scrape.yaml` | ServiceMonitor — auto-scrapes `/metrics` endpoint |
| `alerting-rules.yaml` | 4 Alertmanager rules: PodCrashLooping, HighCPU, HighRAM, ReplicasMismatch |

---

## 7. Automation Scripts

| Script | Role |
|--------|------|
| `deploy.ps1` | **Full e2e deploy:** Terraform → EKS connect → Helm → K8s manifests → DNS pause → Certbot Jenkins HTTPS |
| `destroy.ps1` | **Full teardown:** Helm uninstall (90s LB wait) → K8s cleanup → Terraform destroy |
| `setup.sh` | Auto-installs tools on EC2: AWS CLI, Terraform, kubectl, Helm, Docker, Node.js |
| `stress-test.js` | Load test with real-time RPS, latency, error stats — used for HPA autoscaling demo |

---

## Project Structure

```
DevOps_Final/
├── .github/workflows/
│   └── ci.yml                      # CI/CD: 3 jobs (CI -> Staging -> Production)
├── application/
│   ├── Dockerfile                  # Multi-stage build, non-root user (appuser)
│   ├── main.js                     # Express.js entry point + health check
│   ├── metrics.js                  # Custom Prometheus metrics (prom-client)
│   ├── routes/productRoutes.js     # Product CRUD + S3 upload
│   └── ...
├── infrastructure/
│   ├── provider.tf                 # AWS Provider (Sydney)
│   ├── vpc.tf                      # VPC, Subnets, NAT Gateway
│   ├── eks.tf                      # EKS Cluster + EBS CSI addon + IAM policy
│   ├── s3.tf                       # S3 bucket + IAM
│   ├── jenkins.tf                  # Jenkins EC2 + SG + EIP (lifecycle: create_before_destroy)
│   ├── jenkins-setup.sh            # Auto-install Docker, Jenkins, Nginx, Certbot
│   └── workstation.tf              # DevOps Workstation EC2 (lifecycle: create_before_destroy)
├── kubernetes/
│   ├── staging/
│   │   ├── namespace.yaml          # Namespace: staging
│   │   ├── deployment.yaml         # 1 replica, connects to production MongoDB
│   │   └── service.yaml            # ClusterIP
│   ├── production/
│   │   └── namespace.yaml          # Namespace: production
│   ├── deployment.yaml             # 2 replicas, RollingUpdate
│   ├── service.yaml                # ClusterIP
│   ├── hpa.yaml                    # HPA 2->5 pods
│   ├── mongodb-pvc.yaml            # PVC 1Gi (gp2)
│   ├── mongodb-deployment.yaml     # MongoDB 7
│   ├── mongodb-service.yaml        # MongoDB ClusterIP
│   ├── ingress-ssl.yaml            # NGINX Ingress + TLS
│   ├── alerting-rules.yaml         # 4 Alertmanager rules
│   ├── prometheus-scrape.yaml      # ServiceMonitor
│   └── loki-values.yaml            # Loki Helm values
├── deploy.ps1                      # Full e2e deploy script
├── destroy.ps1                     # Full teardown script
├── setup.sh                        # Tool installer
├── stress-test.js                  # Load test with stats
├── Jenkinsfile                     # Jenkins: checkout -> npm ci -> lint
└── PROJECT_SUMMARY.md              # This file
```
