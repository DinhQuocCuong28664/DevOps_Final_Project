# TECHNICAL REPORT
## Production-Grade CI/CD System for Startup X

---

| | |
|---|---|
| **Course** | Software Deployment, Operations & Maintenance |
| **Assessment** | Final Exam Project (50% of total course grade) |
| **Architecture Tier** | Tier 5 – Expert: Kubernetes-Based Architecture (Amazon EKS) |
| **Production URL** | [https://www.moteo.fun](https://www.moteo.fun) |
| **Repository** | [github.com/DinhQuocCuong28664/DevOps_Final_Project](https://github.com/DinhQuocCuong28664/DevOps_Final_Project) |
| **Container Registry** | [hub.docker.com/r/dinhquoccuong286/devops-final-app](https://hub.docker.com/r/dinhquoccuong286/devops-final-app) |
| **Jenkins URL** | [https://jenkins.moteo.fun](https://jenkins.moteo.fun) |

### Team Members

| Name | Student ID | GitHub | Role |
|------|-----------|--------|------|
| Đinh Quốc Cường | 523H0008 | DinhQuocCuong28664 | Repository Owner |
| Nguyễn Quang Trường | — | nguyenquangtruong08112005 | DevOps Engineer |
| Phạm Minh Hào | — | PhamMHao | DevOps Engineer |

---

## Chapter 1: Overview & System Architecture

### 1.1 Project Overview

This project implements a **production-grade software delivery system** for a simulated startup company ("Startup X"). The system provides end-to-end automation from source code to production, integrating continuous integration, continuous delivery, infrastructure as code, container orchestration, security scanning, and observability. The application is a Node.js/Express.js web platform deployed on Amazon Elastic Kubernetes Service (EKS).

### 1.2 Architecture Tier Selection

The team selected **Tier 5 – Expert: Kubernetes-Based Architecture** as the deployment model. This tier provides the highest potential score and demonstrates mastery of production-grade container orchestration. The justification for this choice is as follows:

- **Self-healing**: Kubernetes automatically replaces failed pods, ensuring high availability.
- **Horizontal Pod Autoscaling (HPA)**: The system scales between 2 and 5 pods based on CPU and memory utilization.
- **Rolling Updates**: Zero-downtime deployments are achieved through the `RollingUpdate` strategy.
- **Ingress Controller**: NGINX Ingress provides unified external access with TLS termination.
- **Namespace Isolation**: Staging and production environments are logically separated.

### 1.3 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            DEVELOPER WORKSTATION                            │
│                                                                             │
│   git push ──► GitHub Repository (main branch)                              │
│                    │                                                        │
│                    ▼                                                        │
│             GitHub Actions CI/CD Pipeline                                   │
│             ┌──────────┐   ┌──────────────┐   ┌────────────────────┐       │
│             │ build-   │──►│ deploy-      │──►│ deploy-            │       │
│             │ and-push │   │ staging      │   │ production         │       │
│             │ (CI)     │   │ (auto)       │   │ (manual approve)   │       │
│             └──────────┘   └──────────────┘   └────────────────────┘       │
└─────────────────────────────────────────────────────────────────────────────┘
                    │                                    │
                    ▼                                    ▼
          ┌─────────────────┐              ┌──────────────────────────────┐
          │  Docker Hub     │              │   AWS Cloud (ap-southeast-2) │
          │  Container      │              │                              │
          │  Registry       │              │  ┌────────────────────────┐  │
          │                 │              │  │      VPC 10.0.0.0/16   │  │
          └─────────────────┘              │  │                        │  │
                                           │  │  ┌──────────────────┐  │  │
                    ┌──────────────────┐   │  │  │  EKS Cluster     │  │  │
                    │  Jenkins EC2     │   │  │  │  v1.30            │  │  │
                    │  t3.small        │   │  │  │                  │  │  │
                    │  (Public Subnet) │   │  │  │  ┌─Staging NS──┐ │  │  │
                    │                  │   │  │  │  │ 1 Pod       │ │  │  │
                    │  - Docker        │   │  │  │  │ ClusterIP   │ │  │  │
                    │  - Jenkins LTS   │   │  │  │  └─────────────┘ │  │  │
                    │  - Nginx + SSL   │   │  │  │                  │  │  │
                    │  - Certbot       │   │  │  │  ┌─Production──┐ │  │  │
                    │                  │   │  │  │  │ 2-5 Pods    │ │  │  │
                    │  jenkins.        │   │  │  │  │ LoadBalancer│ │  │  │
                    │  moteo.fun       │   │  │  │  │ HPA + SSL  │ │  │  │
                    └──────────────────┘   │  │  │  └─────────────┘ │  │  │
                                           │  │  │                  │  │  │
                                           │  │  │  ┌─Monitoring──┐ │  │  │
                                           │  │  │  │ Prometheus  │ │  │  │
                                           │  │  │  │ Grafana     │ │  │  │
                                           │  │  │  │ Alertmanager│ │  │  │
                                           │  │  │  └─────────────┘ │  │  │
                                           │  │  │                  │  │  │
                                           │  │  │  2x t3.medium   │  │  │
                                           │  │  │  Worker Nodes   │  │  │
                                           │  │  └──────────────────┘  │  │
                                           │  └────────────────────────┘  │
                                           └──────────────────────────────┘
```

### 1.4 Technology Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| Application | Node.js / Express.js | 18 (Alpine) |
| **Database** | **MongoDB** (via `mongodb-service` ClusterIP) | 7.x |
| Containerization | Docker (Multi-stage build) | Latest |
| Container Registry | Docker Hub | — |
| **Object Storage** | **AWS S3** (`multer-s3` + `@aws-sdk/client-s3` v3) | v3 |
| Orchestration | Amazon EKS (Kubernetes) | 1.30 |
| Infrastructure as Code | Terraform (AWS + TLS providers) | ~5.0 |
| CI/CD (Primary) | GitHub Actions | v4 |
| CI/CD (Self-Hosted) | Jenkins LTS on EC2 | 2.541.3 |
| Ingress Controller | NGINX Ingress Controller | Latest |
| TLS/SSL | Cert-Manager + Let's Encrypt (ACME v02) | 1.20.x |
| Monitoring | kube-prometheus-stack (Prometheus + Grafana + Alertmanager) | Latest |
| **Centralized Logging** | **Grafana Loki + Promtail** (`loki-stack` Helm chart) | 2.9.x |
| **App Metrics** | **prom-client** v15 (Node.js Prometheus client) | 15.1.x |
| Code Quality | ESLint | v9 |
| Security Scanning | Trivy (Aqua Security) | Latest |
| DNS / Domain | Hostinger (moteo.fun) | — |
| Cloud Provider | AWS (ap-southeast-2, Sydney) | — |

---

## Chapter 2: Infrastructure Provisioning

### 2.1 Approach: Infrastructure as Code (Terraform)

All infrastructure is defined declaratively using **HashiCorp Terraform**, ensuring that every resource is reproducible, version-controlled, and idempotent. The infrastructure code is organized into the following files:

| File | Purpose |
|------|---------|
| `provider.tf` | Declares AWS provider (region `ap-southeast-2`) and TLS provider |
| `vpc.tf` | VPC, subnets, NAT Gateway, DNS hostnames |
| `eks.tf` | EKS cluster, managed node groups, IAM permissions |
| `s3.tf` | S3 bucket for image uploads, public-read policy, IAM policy + attachment to EKS node role |
| `jenkins.tf` | Jenkins EC2 instance, security group, Elastic IP, SSH key pair |
| `jenkins-setup.sh` | User-data script for automated Jenkins provisioning |
| `workstation.tf` | DevOps Workstation EC2 + IAM Instance Profile (no long-lived access keys needed) |

### 2.2 Network Architecture (VPC)

The Virtual Private Cloud is provisioned using the `terraform-aws-modules/vpc/aws` module (v5.5.0):

```
VPC: 10.0.0.0/16  (devops-final-vpc)
│
├── Public Subnets (for Load Balancers, Jenkins EC2)
│   ├── 10.0.101.0/24  (ap-southeast-2a)
│   └── 10.0.102.0/24  (ap-southeast-2b)
│
├── Private Subnets (for EKS Worker Nodes)
│   ├── 10.0.1.0/24    (ap-southeast-2a)
│   └── 10.0.2.0/24    (ap-southeast-2b)
│
├── NAT Gateway (single, for cost optimization)
│   └── Enables private subnet → internet (pulling container images)
│
└── Subnet Tags (mandatory for EKS)
    ├── Public:  kubernetes.io/role/elb = 1
    └── Private: kubernetes.io/role/internal-elb = 1
```

**Design Justification**: Deploying across two Availability Zones (2a, 2b) provides high availability. Worker nodes reside in private subnets for security, while a single NAT Gateway balances cost against availability for a student project.

### 2.3 EKS Cluster Configuration

The Amazon EKS cluster is provisioned using the `terraform-aws-modules/eks/aws` module (v20.x):

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Cluster Name | `devops-final-cluster` | Descriptive naming convention |
| Kubernetes Version | 1.30 | Latest stable release at time of development |
| Node Instance Type | `t3.medium` (2 vCPU, 4 GiB) | Balance of cost and capacity for multiple pods |
| Min/Max/Desired Nodes | 1 / 2 / 2 | Two nodes across AZs for fault tolerance |
| AMI Type | `AL2_x86_64` | Amazon Linux 2, optimized for EKS |
| Endpoint Access | Public | Enables `kubectl` access from developer machines |
| Admin Permissions | Cluster creator auto-admin | Simplified access management |

### 2.4 Jenkins EC2 Server (Bonus Feature)

A dedicated EC2 instance hosts a self-managed Jenkins server:

| Parameter | Value |
|-----------|-------|
| Instance Type | `t3.small` (2 vCPU, 2 GiB) |
| AMI | Ubuntu 22.04 LTS (Jammy Jellyfish) |
| Subnet | Public subnet (for HTTPS access) |
| Storage | 20 GB gp3 EBS volume |
| Elastic IP | Static IP (persists across restarts) |
| SSH Key | Auto-generated RSA-4096 via Terraform TLS provider |

**Security Group Rules**:

| Port | Protocol | Purpose |
|------|----------|---------|
| 22 | TCP | SSH administration |
| 80 | TCP | HTTP (Nginx redirect to HTTPS) |
| 443 | TCP | HTTPS (Nginx + Let's Encrypt) |
| 8080 | TCP | Jenkins UI (direct access fallback) |

**Automated Provisioning** (`jenkins-setup.sh`): The user-data script performs the following on first boot:
1. System update and package installation
2. Docker CE installation from official Docker repository
3. Jenkins LTS (JDK 17) container deployment with persistent volume
4. Nginx reverse proxy configuration for `jenkins.moteo.fun`
5. Certbot installation for automated SSL certificate management

### 2.5 Domain & HTTPS Configuration

| Subdomain | Record Type | Target | Purpose |
|-----------|------------|--------|---------|
| `www.moteo.fun` | CNAME | ELB of NGINX Ingress Controller | Production application |
| `jenkins.moteo.fun` | A | Elastic IP of Jenkins EC2 | Self-hosted CI/CD |

- **Application HTTPS**: Managed by Cert-Manager + Let's Encrypt ClusterIssuer inside Kubernetes
- **Jenkins HTTPS**: Managed by Certbot + Nginx on the EC2 instance

### 2.6 Security Considerations

- SSH private keys (`*.pem`) are excluded from version control via `.gitignore`
- Terraform state files (`*.tfstate`) are excluded from version control
- No hard-coded secrets in any configuration file
- AWS credentials are stored as GitHub Actions encrypted secrets
- Docker container images run as non-root user (`appuser`)

---

## Chapter 3: CI/CD Pipeline Design

### 3.1 Pipeline Architecture Overview

The project implements **two CI/CD systems** for comprehensive coverage:

1. **GitHub Actions** (Primary): Full end-to-end pipeline from code push to production deployment
2. **Jenkins** (Bonus): Self-hosted CI pipeline demonstrating code quality checks

### 3.2 GitHub Actions Pipeline (ci.yml)

The pipeline consists of **three sequential jobs**, triggered on pushes to the `main` branch:

```
┌──────────────────┐     ┌───────────────────┐     ┌─────────────────────┐
│   JOB 1          │     │   JOB 2           │     │   JOB 3             │
│   build-and-push │────►│   deploy-staging  │────►│   deploy-production │
│   (CI)           │     │   (auto)          │     │   (manual approve)  │
│                  │     │                   │     │                     │
│ • Checkout       │     │ • AWS credentials │     │ • AWS credentials   │
│ • Node.js 18     │     │ • EKS kubeconfig  │     │ • EKS kubeconfig    │
│ • npm ci (cached)│     │ • Apply staging   │     │ • Apply production  │
│ • ESLint         │     │   manifests       │     │   manifests         │
│ • Trivy scan     │     │ • Rollout status  │     │ • Health check      │
│ • Docker build   │     │   check           │     │ • Auto-rollback     │
│ • Push to Hub    │     │                   │     │   on failure        │
└──────────────────┘     └───────────────────┘     └─────────────────────┘
```

#### Job 1: build-and-push (Continuous Integration)

| Step | Tool | Description |
|------|------|-------------|
| Checkout | `actions/checkout@v4` | Fetch latest source code |
| Setup Node.js | `actions/setup-node@v4` | Node.js 18 with npm cache |
| Install Dependencies | `npm ci` | Clean, deterministic dependency installation |
| Code Linting | ESLint v9 | Static analysis for code quality |
| Security Scanning | Trivy (`aquasecurity/trivy-action`) | Filesystem scan; fails on CRITICAL/HIGH vulnerabilities |
| Docker Login | `docker/login-action@v3` | Authenticate to Docker Hub |
| Version Tagging | `git rev-parse --short HEAD` | Git commit SHA as image tag (no `latest` tag) |
| Build & Push | `docker/build-push-action@v5` | Multi-stage Docker build, push to registry |

**Dependency Caching**: npm dependencies are cached using `actions/setup-node@v4` with explicit `cache-dependency-path` pointing to `package-lock.json`, significantly reducing installation time on subsequent runs.

**Security Scanning Configuration**:
- Scan type: Filesystem (`fs`)
- Exit code: `1` (fails pipeline on findings)
- Severity filter: `CRITICAL,HIGH` only
- Unfixed vulnerabilities: Ignored (`ignore-unfixed: true`)

#### Job 2: deploy-staging (Automatic Deployment)

After CI passes successfully, this job automatically deploys to the `staging` namespace:

1. Configures AWS credentials and fetches EKS kubeconfig
2. Creates the `staging` namespace (idempotent via `kubectl apply`)
3. Replaces `IMAGE_TAG_PLACEHOLDER` in the staging deployment manifest with the current Git SHA
4. Applies deployment and service manifests
5. Waits for rollout completion with a 120-second timeout

#### Job 3: deploy-production (Manual Approval + Auto-Rollback)

This job requires **manual approval** before execution:

- **GitHub Environment**: `production` with required reviewer `DinhQuocCuong28664`
- The pipeline pauses and displays an approval prompt in the GitHub Actions UI
- Only after a team member approves does the deployment proceed

**Automated Rollback Mechanism**:
```
kubectl rollout status → success? → ✅ Deployment complete
                       → failure? → kubectl rollout undo → exit 1
```

If `kubectl rollout status` fails within the 120-second timeout, the pipeline automatically executes `kubectl rollout undo` to revert to the previous stable version, then exits with code 1 to notify the team.

### 3.3 Jenkins Pipeline (Jenkinsfile)

The self-hosted Jenkins server runs a complementary CI pipeline:

| Stage | Description |
|-------|-------------|
| Checkout SCM | Clones repository from GitHub |
| Install Node.js & Dependencies | Installs Node.js 18 via NVM, then runs `npm ci` |
| Code Linting | Executes `npm run lint` (ESLint v9) |
| Complete | Prints success message |

**Post-build Actions**: Reports success (🎉) or failure (❌) status.

**Jenkins Configuration**:
- Pipeline type: `Pipeline script from SCM`
- SCM: Git (`https://github.com/DinhQuocCuong28664/DevOps_Final_Project.git`)
- Branch: `*/main`
- Agent: `any` (uses NVM for Node.js, avoiding Docker-in-Docker complexity)

### 3.4 Docker Image Build Strategy

The Dockerfile implements a **multi-stage build** pattern:

```
Stage 1 (builder):
  FROM node:18-alpine
  → npm ci --only=production
  → Produces optimized node_modules/

Stage 2 (runtime):
  FROM node:18-alpine
  → Create non-root user (appuser:appgroup)
  → COPY --from=builder node_modules/
  → COPY application source
  → USER appuser
  → EXPOSE 3000
  → CMD ["node", "main.js"]
```

**Security**: The final image runs as a non-privileged user (`appuser`), following DevSecOps best practices.

---

## Chapter 4: Deployment & Orchestration

### 4.1 Multi-Environment Architecture

The system implements **two isolated environments** using Kubernetes namespaces:

| Aspect | Staging | Production |
|--------|---------|------------|
| Namespace | `staging` | `production` |
| Replicas | 1 | 2 (min), 5 (max via HPA) |
| Service Type | ClusterIP (internal) | ClusterIP (internal — external access via NGINX Ingress) |
| Deployment Trigger | Automatic (after CI) | Manual approval required |
| Domain Access | Internal only | `www.moteo.fun` (HTTPS via Ingress) |
| Resource Requests | 100m CPU, 128Mi RAM | 100m CPU, 128Mi RAM |
| Resource Limits | 250m CPU, 256Mi RAM | 250m CPU, 256Mi RAM |

### 4.2 Deployment Strategy: RollingUpdate

Both environments use the `RollingUpdate` strategy with zero-downtime guarantees:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0   # Never terminate existing pods before new ones are ready
    maxSurge: 1          # Create at most 1 additional pod during update
```

**Combined with Readiness Probes**:
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 3
```

This ensures that Kubernetes only routes traffic to pods that have successfully responded to HTTP health checks, preventing users from experiencing downtime during deployments.

### 4.3 Horizontal Pod Autoscaling (HPA)

The production environment uses HPA (`autoscaling/v2`) to automatically scale based on resource utilization:

| Metric | Target | Action |
|--------|--------|--------|
| CPU Utilization | 60% | Scale up when average exceeds 60% |
| Memory Utilization | 70% | Scale up when average exceeds 70% |
| Minimum Replicas | 2 | Always maintains at least 2 pods |
| Maximum Replicas | 5 | Caps scaling at 5 pods |

**Prerequisite**: The Kubernetes Metrics Server must be installed (`kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`) to provide CPU/memory metrics to the HPA controller.

### 4.4 Ingress & TLS Configuration

External access to the production application is managed through the **NGINX Ingress Controller** with automatic TLS certificate management:

```
Internet → NGINX Ingress Controller (AWS ELB — the ONLY LoadBalancer)
               │
               ├── TLS Termination (Let's Encrypt certificate)
               │   └── Secret: moteo-tls-secret
               │
               └── Route: www.moteo.fun → devops-final-service:80 (ClusterIP)
                                              │
                                              └── Pods in production namespace
```

**Design Decision**: The application `Service` (`devops-final-service`) uses `type: ClusterIP` intentionally. This prevents a redundant, insecure second AWS Elastic Load Balancer from being created. All external traffic enters exclusively through the single NGINX Ingress Controller's LoadBalancer, providing a unified entry point with TLS termination.

**Cert-Manager ClusterIssuer**:
- ACME Server: `https://acme-v02.api.letsencrypt.org/directory`
- Challenge Type: HTTP-01 (via NGINX ingress class)
- Automatic renewal before certificate expiration

### 4.5 Self-Healing Demonstration

Kubernetes provides automatic self-healing capabilities:

1. **Scenario**: A running pod is manually terminated using `kubectl delete pod <pod-name> -n production`
2. **Response**: The ReplicaSet controller immediately detects the replica count discrepancy and creates a replacement pod
3. **Recovery Time**: Approximately 5 seconds from deletion to a new pod reaching `Running` state
4. **Monitoring**: The `DeploymentReplicasMismatch` Alertmanager rule fires when available replicas are fewer than desired

### 4.6 Kubernetes Manifest Summary

| Manifest | Namespace | Purpose |
|----------|-----------|---------|
| `staging/namespace.yaml` | — | Creates `staging` namespace |
| `staging/deployment.yaml` | staging | 1-replica deployment with readiness probe |
| `staging/service.yaml` | staging | ClusterIP service (port 80 → 3000) |
| `production/namespace.yaml` | — | Creates `production` namespace |
| `deployment.yaml` | production | 2-replica deployment with RollingUpdate + readiness probe |
| `service.yaml` | production | **ClusterIP** service (port 80 → 3000, internal only) |
| `hpa.yaml` | production | HPA: 2→5 pods, CPU 60%, RAM 70% |
| `mongodb-pvc.yaml` | production / staging | PersistentVolumeClaim 1Gi for MongoDB data |
| `mongodb-deployment.yaml` | production / staging | MongoDB pod (deployed before app by CI pipeline) |
| `mongodb-service.yaml` | production / staging | ClusterIP service exposing MongoDB on port 27017 |
| `ingress-ssl.yaml` | production | NGINX Ingress + ClusterIssuer (Let's Encrypt) |
| `alerting-rules.yaml` | monitoring | 4 PrometheusRule alerts for production |

### 4.7 Persistent Image Storage (AWS S3)

Because the application runs with `replicas: 2` and Kubernetes pods have ephemeral local storage, product images uploaded by users must be stored in a shared, persistent location. Local disk storage would cause images to be lost on pod restart and inaccessible across replicas.

**Solution**: Images are uploaded directly to **AWS S3** using `multer-s3`, eliminating dependency on pod-local storage.

| Component | Detail |
|-----------|--------|
| S3 Bucket | `devops-final-uploads-dqc28664` (fixed name, region `ap-southeast-2`) |
| Terraform Resource | `infrastructure/s3.tf` — provisions bucket, public-read policy, IAM policy |
| Upload Library | `multer-s3` v3 + `@aws-sdk/client-s3` v3 |
| IAM Permission | EKS node role attached with `s3:PutObject`, `s3:GetObject`, `s3:DeleteObject` |
| Public Access | `s3:GetObject` allowed for `Principal: *` on `uploads/*` prefix (browser can load images) |
| Env Variables | `S3_BUCKET_NAME` and `AWS_REGION` injected via `deployment.yaml` (both staging + production) |
| Dev Fallback | If `S3_BUCKET_NAME` is unset, app falls back to local `public/uploads/` (development only) |

**Upload Flow**:
```
User selects image → POST /products (multipart/form-data)
  → multer-s3 streams file directly to S3
  → file.location (S3 HTTPS URL) stored in DB as imageUrl
  → Browser loads image directly from S3 (no proxy through app server)
```

---

## Chapter 5: Monitoring, Observability & Lessons Learned

### 5.1 Monitoring Stack

The observability layer is deployed using the **kube-prometheus-stack** Helm chart, which bundles:

| Component | Purpose |
|-----------|---------|
| **Prometheus** | Time-series metrics collection and storage |
| **Grafana** | Dashboard visualization and alerting UI |
| **Alertmanager** | Alert routing, grouping, and notification |
| **kube-state-metrics** | Exports Kubernetes object state metrics |
| **node-exporter** | Exports host-level system metrics |

### 5.2 Grafana Dashboards

Built-in dashboards provide real-time visibility into:

- **CPU Usage**: Per-pod and per-node CPU utilization over time
- **Memory Usage**: Working set memory consumption by container and node
- **Pod Status**: Running, pending, failed, and restarting pod counts
- **Network I/O**: Ingress and egress traffic patterns
- **Kubernetes Cluster Health**: Node readiness, resource allocation

Access method: `kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80` → `http://localhost:3000`

### 5.3 Custom Alerting Rules

Four custom PrometheusRule alerts are configured for the `production` namespace:

| Alert | Expression | Severity | For Duration |
|-------|-----------|----------|--------------|
| **PodCrashLooping** | `rate(kube_pod_container_status_restarts_total{namespace="production"}[5m]) > 0` | Critical | 2 minutes |
| **HighCPUUsage** | CPU usage > 80% of resource limits | Warning | 3 minutes |
| **HighMemoryUsage** | Memory usage > 85% of resource limits | Warning | 3 minutes |
| **DeploymentReplicasMismatch** | Available replicas < desired replicas | Critical | 1 minute |

These alerts ensure that the team is notified immediately when:
- A pod enters a crash loop (CrashLoopBackOff)
- Resource consumption approaches configured limits
- The deployment is unable to maintain the desired replica count (e.g., after a node failure or pod deletion)

### 5.4 Centralized Logging with Loki + Promtail

To complement Prometheus metrics, **Grafana Loki** (the "Prometheus for logs") is deployed alongside **Promtail** (the log collection agent) using the `grafana/loki-stack` Helm chart. Both components share the `monitoring` namespace with the existing kube-prometheus-stack, reusing the same Grafana instance.

**Architecture:**

```
[All Pods in EKS]  --stdout/stderr-->
    [Promtail DaemonSet]  --push-->
        [Loki]  <--query--  [Grafana Explore (LogQL)]
```

**Deployment:**
```bash
helm upgrade --install loki-stack grafana/loki-stack \
    --namespace monitoring \
    --values kubernetes/loki-values.yaml
```

**Key configuration** (`kubernetes/loki-values.yaml`):
- `loki.enabled: true` — runs Loki in single-binary mode
- `promtail.enabled: true` — DaemonSet deploys on every node, collects pod logs via CRI
- `grafana.enabled: false` — reuses the existing Grafana from kube-prometheus-stack
- **Retention**: 7 days (168 hours)

**Querying logs in Grafana:**

| LogQL Example | Description |
|---------------|-------------|
| `{namespace="production"}` | All logs from production namespace |
| `{namespace="production"} \|= "error"` | Filter for error lines |
| `{app="devops-final-app", namespace="production"} \|= "500"` | HTTP 500 errors from app |
| `{namespace="production"} \| json \| level="error"` | JSON-structured error logs |

**Access:** Grafana → Explore → Data Source: **Loki** → enter LogQL query.

### 5.5 Custom Application-Level Metrics

Beyond infrastructure metrics, the application itself exposes **business-level metrics** via the `prom-client` library (the official Prometheus client for Node.js). This is implemented in a dedicated `metrics.js` module that is imported by `main.js`.

**5 custom metrics defined:**

| Metric | Type | Labels | Description |
|--------|------|--------|-------------|
| `moteo_http_requests_total` | Counter | `method`, `route`, `status_code` | Total HTTP requests received |
| `moteo_http_request_duration_ms` | Histogram | `method`, `route`, `status_code` | Request processing time in ms |
| `moteo_http_active_requests` | Gauge | — | Requests currently being processed |
| `moteo_product_operations_total` | Counter | `operation`, `status` | Product CRUD operations (create/read/update/delete) |
| `moteo_file_uploads_total` | Counter | `status` | S3 image upload success/failure count |

Plus all **Node.js default metrics** (`moteo_` prefix): heap usage, GC duration, event loop lag, active handles.

**How it works:**

```
HTTP Request → metricsMiddleware → [route handler] → res.finish event
                     ↓                                       ↓
             httpActiveRequests.inc()              httpRequestsTotal.inc()
                                                  httpRequestDurationMs.observe()
                                                  httpActiveRequests.dec()
```

**Prometheus scrape config** (`kubernetes/prometheus-scrape.yaml`):
- `ServiceMonitor` CRD (Prometheus Operator) — auto-discovers the app service
- Scrapes `GET /metrics` every **15 seconds**
- Scoped to namespace `production`

**Sample PromQL queries for Grafana dashboards:**

```promql
# HTTP requests per second (all routes)
sum(rate(moteo_http_requests_total[1m]))

# 95th percentile latency
histogram_quantile(0.95, sum(rate(moteo_http_request_duration_ms_bucket[5m])) by (le))

# Error rate (4xx + 5xx)
sum(rate(moteo_http_requests_total{status_code=~"[45].."}[1m]))
/ sum(rate(moteo_http_requests_total[1m]))

# Product create operations
rate(moteo_product_operations_total{operation="create"}[5m])
```

### 5.6 Lessons Learned

1. **EKS Metrics Server**: AWS EKS does not include the Kubernetes Metrics Server by default. Without it, HPA reports `<unknown>` for CPU/memory targets. This must be installed separately after cluster creation.

2. **Docker-in-Docker Limitations**: Running Docker commands inside a Jenkins container requires either Docker-in-Docker (DinD) or socket mounting. We opted for NVM-based Node.js installation instead, which proved simpler and more reliable.

3. **Terraform Destroy Order**: LoadBalancer-type services create AWS Elastic Load Balancers with associated Elastic Network Interfaces (ENIs). These must be cleaned up (by deleting Helm releases and namespaces) before running `terraform destroy`, otherwise the VPC deletion will fail due to ENI dependencies.

4. **DNS Propagation**: After infrastructure recreation, all Load Balancer endpoints change. DNS records on the domain registrar (Hostinger) must be updated with new CNAME/A values, and propagation can take 1–5 minutes.

5. **Cost Management**: The complete infrastructure (EKS cluster + 2× t3.medium nodes + Jenkins t3.small + NAT Gateway + Elastic IPs) incurs ongoing AWS charges. A systematic provisioning and teardown procedure (`Guiding_light.md`) was created to enable on-demand infrastructure lifecycle management.

6. **Multi-Stage Docker Builds**: Separating the dependency installation stage from the runtime stage significantly reduces the final image size and improves security by excluding build tools from the production container.

7. **GitHub Environment Protection Rules**: Configuring required reviewers on the `production` environment provides a critical safety gate, preventing untested code from reaching production without human verification.

---

## Appendix A: Repository Structure

```
DevOps_Final/
├── .github/workflows/
│   └── ci.yml                      # CI/CD Pipeline: 3 jobs (CI → Staging → Production)
├── application/
│   ├── Dockerfile                  # Multi-stage build, non-root user (appuser)
│   ├── .dockerignore               # Excludes node_modules, .git from build context
│   ├── eslint.config.mjs           # ESLint v9 configuration
│   ├── main.js                     # Express.js entry point
│   ├── package.json                # Application dependencies
│   ├── controllers/                # Business logic layer
│   ├── models/                     # Data models
│   ├── routes/                     # API route definitions
│   ├── services/                   # Service layer
│   ├── validators/                 # Input validation
│   ├── views/                      # EJS templates
│   └── public/                     # Static assets
├── infrastructure/
│   ├── provider.tf                 # AWS + TLS Terraform providers
│   ├── vpc.tf                      # VPC, subnets, NAT Gateway
│   ├── eks.tf                      # EKS cluster + managed node groups
│   ├── s3.tf                       # S3 bucket for image uploads + IAM policy
│   ├── jenkins.tf                  # Jenkins EC2 + Security Group + EIP
│   ├── jenkins-setup.sh            # Automated Jenkins provisioning script
│   └── workstation.tf              # DevOps Workstation EC2 + IAM Instance Profile (no access keys)
├── kubernetes/
│   ├── staging/
│   │   ├── namespace.yaml          # Staging namespace
│   │   ├── deployment.yaml         # 1 replica, RollingUpdate, readinessProbe
│   │   └── service.yaml            # ClusterIP (internal access only)
│   ├── production/
│   │   └── namespace.yaml          # Production namespace
│   ├── deployment.yaml             # 2 replicas, RollingUpdate, readiness probe
│   ├── service.yaml                # ClusterIP (internal — traffic via Ingress)
│   ├── hpa.yaml                    # HPA: 2→5 pods, CPU 60%, RAM 70%
│   ├── mongodb-pvc.yaml            # PersistentVolumeClaim 1Gi for MongoDB data
│   ├── mongodb-deployment.yaml     # MongoDB pod (deployed before app by CI pipeline)
│   ├── mongodb-service.yaml        # ClusterIP service exposing MongoDB on port 27017
│   ├── ingress-ssl.yaml            # NGINX Ingress + Let's Encrypt TLS
│   ├── alerting-rules.yaml         # 4 Alertmanager rules (production)
│   ├── loki-values.yaml            # Loki Stack Helm values (Loki + Promtail, 7-day retention)
│   └── prometheus-scrape.yaml      # ServiceMonitor — Prometheus auto-scrape /metrics every 15s
├── setup.sh                        # Workstation bootstrap: installs AWS CLI, Terraform, kubectl, Helm, Docker, Node.js
├── Jenkinsfile                     # Jenkins pipeline (checkout → npm ci → lint)
├── stress-test.js                  # HTTPS load test (200 concurrent users)
├── Guiding_light.md                # Infrastructure lifecycle guide (apply ↔ destroy)
├── Final_Project.md                # Project rubric & progress tracker
├── Final_Project_Student_Checklist.md # Student checklist
└── .gitignore                      # Excludes *.tfstate, *.pem, .terraform/
```

## Appendix B: Bonus Features Summary

| # | Feature | Implementation | Evidence |
|---|---------|---------------|----------|
| 7.1 | Self-Hosted CI/CD | Jenkins 2.541.3 on EC2 t3.small, HTTPS via Nginx + Certbot | `jenkins.moteo.fun`, `jenkins.tf`, `Jenkinsfile` |
| 7.2 | Multi-Environment + Approval Gates | Staging (auto) → Production (manual approve via GitHub Environments) | `ci.yml` (3 jobs), `staging/`, `production/` |
| 7.3 | Advanced Deployment Strategy | RollingUpdate with `maxUnavailable: 0, maxSurge: 1` (zero-downtime) | `deployment.yaml` |
| 7.4 | Automated Rollback | `kubectl rollout status` → failure → `kubectl rollout undo` | `ci.yml` (Job 3) |

### Architectural Improvements

| Improvement | Problem Solved | Implementation |
|-------------|---------------|----------------|
| S3 Image Storage | Images lost on pod restart/scaling (ephemeral disk) | `multer-s3`, `infrastructure/s3.tf`, S3 env vars in `deployment.yaml` |
| ClusterIP Service | Redundant second LoadBalancer created alongside Ingress | `service.yaml` changed from `LoadBalancer` to `ClusterIP` |
| HTTPS Stress Test | HTTP stress test blocked by NGINX 308 redirect | `stress-test.js` migrated to `https` module |

---

*End of Technical Report*
