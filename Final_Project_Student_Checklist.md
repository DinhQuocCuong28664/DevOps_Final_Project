# Final Exam Project: Student Checklist

**Course:** Software Deployment, Operations & Maintenance  
**Assessment:** Final Exam Project (50%)

> **⚠️ IMPORTANT:** Any feature, improvement, or advanced functionality will be recognized for grading ONLY IF it:
> - appears in the video demo and/or live in-class presentation, AND
> - is clearly explained and evidenced in the technical report.
> 
> *If a feature is implemented but not shown in the demo and not documented in the report, it will be treated as non-existent for grading purposes.*

---

## 🏗️ 1. Architecture Selection
- [ ] You must select one architecture tier and clearly state it in the technical report:
  - [ ] Tier 1: Single-Server, Non-Containerized Deployment
  - [ ] Tier 2: Single-Server, Containerized Deployment (Docker Compose)
  - [ ] Tier 3: Multi-Server Architecture with Centralized Load Balancing
  - [ ] Tier 4: Docker Swarm–Based Orchestration
  - [ ] Tier 5: Kubernetes-Based Architecture
- [ ] The deployed system must actually match the selected tier in practice.
- [ ] The system must be operational and reachable.

## 🌐 2. Infrastructure & Environment
- [ ] A real cloud provider is used (AWS, Azure, GCP, Oracle Cloud, DigitalOcean, etc.).
- [ ] At least one Ubuntu server is provisioned and accessible.
- [ ] A registered domain name points to the deployed system.
- [ ] HTTPS is correctly configured using Let's Encrypt or an equivalent CA.
- [ ] Provisioning approach:
  - [ ] Manual provisioning (acceptable, lower score), or
  - [ ] Infrastructure as Code (Terraform ± Ansible, higher score).
- [ ] Evidence of infrastructure setup is included in the technical report.

## ⚙️ 3. Pipeline: Continuous Integration (CI)
- [ ] The pipeline is triggered automatically by a code push.
- [ ] CI includes:
  - [ ] linting or code quality checks
  - [ ] dependency caching
  - [ ] build artifact generation
  - [ ] security scanning (Trivy / Snyk / SonarQube / equivalent)
- [ ] The pipeline fails on Critical/High vulnerabilities.
- [ ] For containerized tiers (Tier 2–5), Docker images are built, version-tagged, and pushed to a registry.

## 🚀 4. Pipeline: Continuous Delivery (CD)
- [ ] CD automatically deploys to production:
  - [ ] pull correct artifact/image version
  - [ ] update deployment configuration
  - [ ] deploy new version
  - [ ] restart services safely
- [ ] If staging and production are both used:
  - [ ] environment separation
  - [ ] manual approval gate
  - [ ] documented deployment strategy

## 📦 5. Deployment Implementation
- [ ] Deployment behavior matches the selected tier. Tier expectations:
  - [ ] Tier 1: systemd or PM2, auto-restart after reboot
  - [ ] Tier 2: Docker Compose, multi-container, persistent volumes
  - [ ] Tier 3: multiple servers with managed cloud load balancer preferred
  - [ ] Tier 4: Docker Swarm cluster with replicated services
  - [ ] Tier 5: Kubernetes with Services, Ingress, self-healing
- [ ] Horizontal scaling is demonstrated where applicable.

## 📊 6. Monitoring & Observability
- [ ] Prometheus is installed and collecting metrics.
- [ ] Grafana dashboards are accessible.
- [ ] Dashboards show:
  - [ ] CPU usage
  - [ ] memory usage
  - [ ] service/container/pod status
- [ ] Monitoring reflects the real production system and is shown during the demo.

## 🎬 7. Mandatory Demo Scenario
- [ ] A real source code change is made, committed, and pushed.
- [ ] CI pipeline runs automatically and visibly.
- [ ] CD deploys the new version automatically.
- [ ] Production website shows the updated version.
- [ ] HTTPS validity is verified.
- [ ] Grafana dashboards are opened and explained.
- [ ] A failure is simulated and system behavior is observed.

## 📄 8. Technical Report
- [ ] The report follows the official academic template and is written in formal academic English.
- [ ] The report includes exactly five chapters:
  1. Overview & System Architecture
  2. Infrastructure Provisioning
  3. CI/CD Pipeline Design
  4. Deployment & Orchestration
  5. Monitoring, Observability & Lessons Learned
- [ ] Architecture diagrams, evidence, and design justifications are included.

## 📦 9. Submission Artifacts
- [ ] The video follows the mandatory demo scenario step by step. CI/CD execution, deployment, monitoring, and failure behavior are clearly visible.
- [ ] A single `.zip` file is submitted containing:
  - [ ] source code
  - [ ] infrastructure files
  - [ ] CI/CD pipeline configurations
  - [ ] deployment manifests
  - [ ] monitoring configurations
  - [ ] technical report (PDF)
- [ ] The production website URL is included and accessible via HTTPS.
- [ ] All artefacts describe the same system.

## ✅ 10. Final Review
- [ ] The system is running via HTTPS.
- [ ] CI/CD works without manual intervention.
- [ ] All features appear in both the demo and the report.
- [ ] No placeholder or staged content is used.