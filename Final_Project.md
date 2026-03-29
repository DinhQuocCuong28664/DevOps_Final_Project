# 📋 FINAL EXAM PROJECT SPECIFICATION
## Production-Grade CI/CD System

| | |
|---|---|
| **Course** | Software Deployment, Operations & Maintenance |
| **Assessment Type** | Final Exam Project (50% of total course grade) |
| **Duration** | 6 weeks |
| **Team Size** | 2–3 students |

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

### Tier 5 – Expert: Kubernetes-Based Architecture ⭐

> **Highest potential score** for architecture and orchestration.

Production-grade container orchestration using Kubernetes (upstream, K3s, or managed: **EKS**, GKE, AKS).
- Must demonstrate: Deployments, Services, ConfigMaps, Secrets
- **Ingress Controller** required for external access
- **Self-healing** behaviour expected
- **HPA** (Horizontal Pod Autoscaling) strongly encouraged

---

## SECTION IV. TECHNICAL SPECIFICATIONS

### 4.1 Infrastructure Provisioning and Environment Setup

All deployments must be hosted on a **real cloud provider** (AWS, Azure, GCP, Oracle Cloud, DigitalOcean).

#### A. Infrastructure as Code (IaC) — Recommended ⭐

Using tools such as **Terraform** + **Ansible**:
- Provisioning compute resources and networking
- Defining security groups / firewall rules
- Configuring storage resources
- Installing required system dependencies
- All definitions must be **idempotent**

#### B. Manual Infrastructure Provisioning

Acceptable but limits maximum score. Minimum requirements regardless of method:
- ✅ Publicly accessible cloud server
- ✅ Registered domain name resolving to the system
- ✅ HTTPS configured (Let's Encrypt or equivalent)

---

### 4.2 CI/CD Pipeline

#### 4.2.1 Continuous Integration (CI)

| Step | Requirement | Status |
|------|------------|--------|
| **Code Linting** | Static analysis tools appropriate to tech stack | Required |
| **Dependency Caching** | Cache `node_modules`, Maven repos, etc. | Required |
| **Build Artifacts** | Reproducible build (Docker image, JAR, etc.) | Required |
| **Security Scanning** | Trivy/Snyk/SonarQube — **fail on CRITICAL/HIGH** | Required |
| **Image Build & Push** | Explicit version tags (SHA/semver), **NOT** `latest` | Required |

#### 4.2.2 Continuous Delivery (CD)

At minimum, the CD pipeline must:
- Retrieve correct versioned artifact/container image
- Update deployment configurations
- Deploy to production automatically
- Restart/update services in controlled manner

For staging + production environments:
- Separate deployment targets
- Manual approval gate
- Documented deployment strategy (recreate, rolling update)

---

### 4.3 Architecture-Specific Deployment Requirements

| Tier | Requirements |
|------|-------------|
| **Tier 1** | `systemd` or `PM2`, auto-restart after reboot |
| **Tier 2** | Docker Compose, persistent volumes, service scaling |
| **Tier 3** | Cloud managed LB preferred, horizontal scaling |
| **Tier 4** | Swarm cluster, replicated services, cluster scheduling |
| **Tier 5** | K8s Deployments, Services, Ingress. **HPA & self-healing encouraged** |

---

### 4.4 Monitoring and Observability

**Minimum Requirements:**
- ✅ Metrics collection (Prometheus or equivalent)
- ✅ Grafana dashboards: CPU, memory, service/pod status

**Advanced (Encouraged):**
- Alerting via Alertmanager
- Centralized logging (Loki or ELK)
- Custom application-level metrics (request rates, error counts)

> ⚠️ Monitoring components must be **actively demonstrated**, not merely installed.

---

### 4.5 Documentation and Evidence

All implementations must be:
- Fully documented in the technical report
- Supported by screenshots, logs, or configuration excerpts
- Demonstrated in video and live presentation

---

## SECTION V. MANDATORY DEMONSTRATION SCENARIO

### 5.1 Source Code Modification
Make a visible, meaningful change to application source code (UI text, feature, config). Must **not** be pre-staged.

### 5.2 Commit and Push
- Clear commit message
- Correct target branch triggering pipeline
- Successful sync with remote repository

### 5.3 CI Pipeline Execution
Show execution and outcome of **each CI stage**:
- ✅ Code linting and quality checks
- ✅ Dependency restoration and caching
- ✅ Build stage — reproducible artifact
- ✅ Security scanning — vulnerability detection
- ✅ Container image build and registry push

### 5.4 CD Deployment
- Retrieval of correct artifact version
- Updated deployment configurations
- Deployment execution appropriate to tier
- Controlled service restart / rolling update

### 5.5 Verification of Application Update
- Access via public domain name
- Visible change is present
- System accessible via **HTTPS only**
- Correct application behaviour

### 5.6 Monitoring and Observability Validation
- Open Grafana dashboard
- Show real-time metrics (CPU, memory, pod status)
- Explain how metrics reflect current system state

### 5.7 Failure Simulation ⚠️
Simulate failure appropriate to tier:
- Stop/restart a container or service
- Terminate a process or pod
- Simulate node-level failure (clustered environments)

Must show:
- How system responds to failure
- Whether services **recover automatically**
- How failure appears in monitoring dashboards

---

## SECTION VI. SUBMISSION DELIVERABLES

### 6.1 Project Repository and Technical Artefacts
- ✅ Complete application source code
- ✅ Infrastructure provisioning artefacts (Terraform)
- ✅ CI/CD pipeline configuration (GitHub Actions)
- ✅ Deployment artefacts (Dockerfiles, K8s manifests)
- ✅ Monitoring configuration (Prometheus, Grafana)
- ⚠️ **No hard-coded secrets**

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
- ✅ Public domain URL
- ✅ Valid TLS certificate (HTTPS)
- ✅ System remains accessible during grading

### 6.5 Supporting Links
- Source code repository
- Container registry (Docker Hub)
- Monitoring dashboards (if externally accessible)

---

## SECTION VII. EXTRA CREDIT (Bonus)

Each bonus: **0.25 – 0.5 points**. Must be functional, demonstrated, and documented.

### 7.1 Self-Hosted CI/CD Infrastructure
Deploy own GitLab/Jenkins on separate machine with custom domain + HTTPS.

### 7.2 Multi-Environment Deployment with Approval Gates
Staging + Production with manual approval step.

### 7.3 Advanced Deployment Strategies
Rolling updates, blue–green deployment, or canary releases.

### 7.4 Automated Rollback Mechanisms
Triggered by failed health checks, deployment errors, or pipeline failures.

### 7.5 Bonus Award Conditions
- Must reach **competent implementation level**
- Incomplete/unstable features = **no bonus**
- Cannot compensate for missing core requirements