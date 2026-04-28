# DevOps Final Project — Build Summary

> **Project:** Deploy a Node.js application to Amazon EKS with a fully automated CI/CD Pipeline
> **Domain:** [https://www.moteo.fun](https://www.moteo.fun)
> **Architecture:** Tier 5 (Highest level)

---

## 1. Infrastructure as Code (IaC)

**Achievement:** Wrote Terraform files (`provider.tf`, `vpc.tf`, `eks.tf`) to automate the provisioning of the network and Kubernetes cluster (Amazon EKS) on AWS.

**Highlights:**
- Implemented **Tier 5** architecture — deploying directly to Kubernetes instead of manual provisioning.
- Excluded sensitive files (Access Keys `.csv`) and infrastructure state (`terraform.tfstate`) from GitHub via `.gitignore`.
- Created a dedicated IAM User (`devops-admin`) with least-privilege permissions instead of using the dangerous Root account.

| File | Role |
|------|------|
| `provider.tf` | Declares the Sydney region (`ap-southeast-2`) |
| `vpc.tf` | VPC, Public/Private Subnets, NAT Gateway |
| `eks.tf` | EKS Cluster (K8s 1.30), 2x Worker Nodes `t3.medium` |

---

## 2. DevSecOps and Container Optimization

**Achievement:** Packaged the Node.js application using an enterprise-grade Dockerfile.

**Highlights:**
- Used **Multi-stage Build** to minimize image size — keeping only production dependencies.
- Configured the app to run as a **non-root user** (`appuser`) to prevent privilege escalation.
- Fixed **CrashLoopBackOff** caused by directory permission errors (`EACCES: permission denied, mkdir '/app/public/uploads'`) by pre-creating the directory and using `chown` before switching to the non-root user.

---

## 3. Fully Automated CI/CD Pipeline

**Achievement:** Built a `ci.yml` file on GitHub Actions to automate 100% of the flow from code to production.

**Pipeline flow:**
```
Code Push -> Checkout -> Node.js Setup -> npm ci -> Trivy Scan -> Docker Build & Push -> Deploy to EKS
```

**Highlights:**
- Passed a strict security scan. When **Trivy** detected **10 HIGH vulnerabilities** in dependencies (`multer`, `minimatch`, `nodemon`), resolved them by upgrading to safe versions instead of ignoring them.
- Docker Images are always tagged with the **Git commit SHA** instead of the dangerous `latest` tag — ensuring precise version traceability.

---

## 4. Production Deployment (Continuous Delivery)

**Achievement:** Wrote Kubernetes manifests (`deployment.yaml`, `service.yaml`) and configured GitHub Actions to automatically connect to AWS and update the application on every new code push.

| File | Role |
|------|------|
| `deployment.yaml` | 2 replicas, resource limits, image tag placeholder for CD |
| `service.yaml` | **ClusterIP**, port 80 -> container port 3000 (internal, traffic via Ingress) |

**How it works:** The CD pipeline uses `sed` to replace `IMAGE_TAG_PLACEHOLDER` with the latest commit SHA, then runs `kubectl apply` to update the EKS cluster.

---

## 5. Custom Domain and HTTPS Security

**Achievement:** Application running on the custom domain **[www.moteo.fun](https://www.moteo.fun)** with full HTTPS.

**Highlights:**
- Installed **NGINX Ingress Controller** as the single entry point for the Kubernetes cluster.
- Deployed **Cert-Manager** + **Let's Encrypt** for automatic SSL/TLS certificate provisioning and renewal.
- Website shows a green padlock (HTTPS) — meets production security standards.

| Component | Version |
|-----------|---------|
| Ingress NGINX Controller | v1.10.0 |
| Cert-Manager | v1.14.4 |
| Let's Encrypt | ACME v02 (Production) |

---

## Project Structure

```
DevOps_Final/
├── .github/workflows/
│   └── ci.yml                  # CI/CD Pipeline (GitHub Actions)
├── application/
│   ├── Dockerfile              # Multi-stage build, non-root user
│   ├── .dockerignore           # Reduces build context size
│   ├── .gitignore              # Excludes node_modules, .env, logs
│   ├── main.js                 # Entry point (Express.js)
│   ├── package.json            # Dependencies (0 vulnerabilities)
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
│   ├── s3.tf                   # S3 bucket for image uploads + IAM policy
│   ├── jenkins.tf              # Jenkins EC2 + Security Group + EIP
│   └── workstation.tf          # DevOps Workstation EC2 + IAM Instance Profile
├── kubernetes/
│   ├── deployment.yaml         # 2 replicas, resource limits
│   ├── service.yaml            # ClusterIP Service
│   └── ingress-ssl.yaml        # Ingress + TLS (Let's Encrypt)
├── .gitignore                  # Excludes .terraform, tfstate, .csv
├── setup.sh                    # Auto-installs tools on EC2 (AWS CLI, Terraform, kubectl, Helm, Docker, Node.js)
└── PROJECT_SUMMARY.md          # This file
```
