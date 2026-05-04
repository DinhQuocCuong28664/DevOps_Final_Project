# TECHNICAL REPORT

## Production-Grade CI/CD System for Startup X

---

| | |
|---|---|
| **Course** | Software Deployment, Operations & Maintenance |
| **Assessment** | Final Exam Project (50% of total course grade) |
| **Architecture Tier** | Tier 5 – Expert: Kubernetes-Based Architecture (Amazon EKS) |
| **Production URL** | [https://www.moteo.fun](https://www.moteo.fun) |
| **Staging URL** | [https://staging.moteo.fun](https://staging.moteo.fun) |
| **Repository** | [github.com/DinhQuocCuong28664/DevOps_Final_Project](https://github.com/DinhQuocCuong28664/DevOps_Final_Project) |
| **Container Registry** | [hub.docker.com/r/dinhquoccuong286/devops-final-app](https://hub.docker.com/r/dinhquoccuong286/devops-final-app) |
| **Jenkins URL** | [https://jenkins.moteo.fun](https://jenkins.moteo.fun) |

**Table 1: Project Metadata**

### Team Members

**Table 2: Team Members**

| Name | Student ID | GitHub | Role |
|------|-----------|--------|------|
| Đinh Quốc Cường | 523H0008 | DinhQuocCuong28664 | Repository Owner |
| Nguyễn Quang Trường | — | nguyenquangtruong08112005 | DevOps Engineer |
| Phạm Minh Hào | — | PhamMHao | DevOps Engineer |


---

## List of Abbreviations

| Abbreviation | Full Form |
|-------------|-----------|
| ACME | Automated Certificate Management Environment |
| AMI | Amazon Machine Image |
| AWS | Amazon Web Services |
| CI/CD | Continuous Integration / Continuous Deployment |
| CIDR | Classless Inter-Domain Routing |
| CNAME | Canonical Name |
| CPU | Central Processing Unit |
| CRD | Custom Resource Definition |
| CRI | Container Runtime Interface |
| CRUD | Create, Read, Update, Delete |
| CSI | Container Storage Interface |
| DNS | Domain Name System |
| EBS | Elastic Block Store |
| EC2 | Elastic Compute Cloud |
| EKS | Elastic Kubernetes Service |
| ELB | Elastic Load Balancer |
| ENI | Elastic Network Interface |
| ESLint | ECMAScript Lint |
| GiB | Gibibyte |
| gp3 | General Purpose SSD (3rd generation) |
| HPA | Horizontal Pod Autoscaler |
| HTTP | Hypertext Transfer Protocol |
| HTTPS | Hypertext Transfer Protocol Secure |
| IAM | Identity and Access Management |
| IaC | Infrastructure as Code |
| JSON | JavaScript Object Notation |
| LTS | Long-Term Support |
| LogQL | Log Query Language |
| NAT | Network Address Translation |
| NGINX | Engine-X |
| NVM | Node Version Manager |
| PVC | PersistentVolumeClaim |
| RAM | Random Access Memory |
| RSA | Rivest–Shamir–Adleman |
| S3 | Simple Storage Service |
| SCM | Source Code Management |
| SHA | Secure Hash Algorithm |
| SSH | Secure Shell |
| SSL | Secure Sockets Layer |
| TLS | Transport Layer Security |
| URL | Uniform Resource Locator |
| vCPU | Virtual Central Processing Unit |
| VPC | Virtual Private Cloud |
| YAML | YAML Ain't Markup Language |

---

## Chapter 1: Overview & System Architecture

### 1.1 Project Overview

This project presents the design and implementation of a production-grade software delivery system for a simulated enterprise referred to as "Startup X." The system establishes an end-to-end automated pipeline that spans the entire software delivery lifecycle, encompassing source code management, continuous integration, continuous delivery, infrastructure provisioning, container orchestration, security integration, and comprehensive observability. The application at the core of this system is a Node.js web platform built on the Express.js framework, which is deployed on Amazon Elastic Kubernetes Service (EKS) within the AWS cloud infrastructure.

The primary objective of this project is to demonstrate mastery of modern DevOps practices by constructing a system that is reproducible, resilient, observable, and secure. Rather than focusing solely on application functionality, the project emphasises the operational maturity of the delivery pipeline and the production readiness of the deployment environment.

### 1.2 Architecture Tier Selection

The team selected **Tier 5 – Expert: Kubernetes-Based Architecture** as the deployment model for this project. This tier represents the highest level of architectural complexity and offers the greatest potential score for orchestration and scalability. The decision to adopt Kubernetes was driven by several technical considerations that align with enterprise-grade operational requirements.

First, Kubernetes provides native self-healing capabilities through its ReplicaSet controller, which automatically replaces failed pods to maintain the desired replica count. This ensures high availability without manual intervention. Second, the Horizontal Pod Autoscaler (HPA) enables the system to dynamically adjust its capacity between two and five replicas based on real-time CPU and memory utilisation, thereby accommodating fluctuating user demand. Third, the RollingUpdate deployment strategy facilitates zero-downtime deployments by gradually replacing old pods with new ones while maintaining service availability throughout the transition. Fourth, the NGINX Ingress Controller provides a unified external access point with TLS termination, eliminating the need for multiple load balancers. Finally, Kubernetes namespaces enable logical isolation between staging and production environments, allowing the team to validate changes in a safe environment before promoting them to production.

### 1.3 High-Level Architecture

The system architecture is organised into several distinct layers, each responsible for a specific aspect of the delivery pipeline. The following diagram illustrates the overall system structure and the flow of traffic from source code changes through to the production deployment.

```
[Figure 1: High-Level System Architecture Diagram]
```
*Screenshot: Architecture diagram showing the four domains — Development & CI/CD, Container Registry, Cloud Infrastructure (AWS EKS), and Monitoring & Observability.*

The architecture can be understood as comprising four primary domains. The **development and CI/CD domain** includes the GitHub repository, the GitHub Actions pipeline, and the self-hosted Jenkins server. The **container registry domain** consists of Docker Hub, which stores versioned application images. The **cloud infrastructure domain** encompasses the AWS Virtual Private Cloud (VPC), the EKS cluster, and supporting services such as S3 for object storage. The **monitoring and observability domain** includes Prometheus, Grafana, Alertmanager, and Loki, all deployed within the Kubernetes cluster.

### 1.4 Technology Stack

The following table enumerates the technologies employed in this project, along with their respective versions and roles within the system.

**Table 3: Technology Stack**

| Layer | Technology | Version | Role |
|-------|-----------|---------|------|
| Application Runtime | Node.js / Express.js | 18 (Alpine) | Web application framework |
| Database | MongoDB | 7.x | Persistent data storage |
| Containerisation | Docker (Multi-stage build) | Latest | Application packaging |
| Container Registry | Docker Hub | — | Image distribution |
| Object Storage | AWS S3 | — | Persistent image uploads |
| Orchestration | Amazon EKS (Kubernetes) | 1.30 | Container orchestration |
| Infrastructure as Code | Terraform | ~5.0 | Infrastructure provisioning |
| CI/CD (Primary) | GitHub Actions | v4 | Automated pipeline |
| CI/CD (Self-Hosted) | Jenkins LTS on EC2 | 2.541.3 | Supplementary CI |
| Ingress Controller | NGINX Ingress Controller | Latest | External traffic routing |
| TLS/SSL | Cert-Manager + Let's Encrypt | 1.20.x | Automated certificate management |
| Monitoring | kube-prometheus-stack | Latest | Metrics collection and visualisation |
| Centralised Logging | Grafana Loki + Promtail | 2.9.x | Log aggregation |
| Application Metrics | prom-client | 15.1.x | Custom Node.js metrics |
| Code Quality | ESLint | v9 | Static code analysis |
| Security Scanning | Trivy (Aqua Security) | Latest | Vulnerability detection |
| DNS / Domain | Hostinger (moteo.fun) | — | Domain name resolution |
| Cloud Provider | AWS (ap-southeast-2) | — | Cloud infrastructure |

### 1.5 Design Decisions and Trade-offs

Several architectural decisions warrant explicit justification. The choice of **Amazon EKS over self-managed Kubernetes** was motivated by the desire to offload control plane management to AWS, thereby reducing operational overhead while retaining full control over worker nodes and application configuration. This trade-off involves higher cost compared to a self-hosted solution but provides greater reliability and integration with AWS services such as Elastic Load Balancing and IAM.

The decision to use **GitHub Actions as the primary CI/CD platform** rather than Jenkins was based on its native integration with the GitHub repository, which eliminates the need for webhook configuration and credential management between separate systems. Jenkins was retained as a supplementary system to demonstrate self-hosted CI/CD capabilities as a bonus feature.

The selection of **two Availability Zones** within the Sydney region (ap-southeast-2) provides a balance between high availability and cost. While three zones would offer greater fault tolerance, the additional NAT Gateway and cross-zone data transfer costs were deemed disproportionate for a student project.

---

## Chapter 2: Infrastructure Provisioning

### 2.1 Approach: Infrastructure as Code

All cloud infrastructure for this project is defined declaratively using HashiCorp Terraform. This approach ensures that every resource is reproducible, version-controlled, and idempotent. The infrastructure code is organised into modular files, each responsible for a distinct aspect of the environment. The following table summarises the purpose of each Terraform configuration file.

**Table 4: Terraform Configuration Files**

| File | Purpose |
|------|---------|
| `provider.tf` | Declares the AWS provider configured for the ap-southeast-2 region and the TLS provider for SSH key generation |
| `vpc.tf` | Defines the Virtual Private Cloud, public and private subnets, NAT Gateway, and DNS hostname settings |
| `eks.tf` | Provisions the EKS cluster, managed node groups, IAM roles, and the EBS CSI driver addon |
| `s3.tf` | Creates the S3 bucket for image uploads, configures public-read access policy, and attaches an IAM policy to the EKS node role |
| `jenkins.tf` | Provisions the Jenkins EC2 instance, security group, Elastic IP, and SSH key pair |
| `jenkins-setup.sh` | Provides the user-data script that automates Jenkins installation on first boot |
| `workstation.tf` | Provisions a DevOps workstation EC2 instance with an IAM instance profile, eliminating the need for long-lived access keys |

The idempotency of these configurations was verified by executing `terraform apply` multiple times against the same state file. In each case, Terraform reported that no changes were necessary, confirming that the infrastructure definitions produce consistent results without unintended side effects.

```
[Figure 2: Terraform Apply Output — Idempotency Verification]
```
*Screenshot: Terminal output showing `terraform apply` reporting "No changes. Your infrastructure matches the configuration."*

### 2.2 Network Architecture

The Virtual Private Cloud is provisioned using the community-maintained `terraform-aws-modules/vpc/aws` module at version 5.5.0. The network is designed with a clear separation between public and private subnets, following AWS best practices for security and accessibility.

```
[Figure 3: VPC Network Topology Diagram]
```
*Screenshot: AWS VPC console showing the VPC (10.0.0.0/16), two public subnets, two private subnets, and the NAT Gateway.*

The VPC occupies the CIDR block 10.0.0.0/16 and spans two Availability Zones within the Sydney region. Two public subnets (10.0.101.0/24 and 10.0.102.0/24) host resources that require direct internet access, namely the NGINX Ingress Controller's load balancer and the Jenkins EC2 instance. Two private subnets (10.0.1.0/24 and 10.0.2.0/24) host the EKS worker nodes, which do not require direct inbound internet access.

A single NAT Gateway is deployed in the first public subnet to enable outbound internet connectivity for resources in the private subnets. This design choice represents a deliberate trade-off between cost and availability. While deploying NAT Gateways in each Availability Zone would provide greater resilience against zone failures, the associated cost was considered prohibitive for a student project. The single NAT Gateway configuration is therefore deemed acceptable, with the understanding that a production deployment would warrant a fully redundant setup.

The subnet tagging convention required by EKS is applied explicitly: public subnets are tagged with `kubernetes.io/role/elb = 1`, and private subnets are tagged with `kubernetes.io/role/internal-elb = 1`. These tags enable the Kubernetes cloud provider to automatically discover and provision load balancers in the appropriate subnets.

### 2.3 EKS Cluster Configuration

The Amazon EKS cluster is provisioned using the `terraform-aws-modules/eks/aws` module at version 20.x. The cluster runs Kubernetes version 1.30, which was the latest stable release at the time of development. The following table presents the key configuration parameters and their justifications.

**Table 5: EKS Cluster Configuration Parameters**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Cluster Name | `devops-final-cluster` | Descriptive naming for easy identification |
| Kubernetes Version | 1.30 | Latest stable release with extended support |
| Node Instance Type | `t3.medium` (2 vCPU, 4 GiB) | Sufficient capacity for multiple pods at minimal cost |
| Min / Max / Desired Nodes | 1 / 2 / 2 | Two nodes across Availability Zones for fault tolerance |
| AMI Type | `AL2_x86_64` | Amazon Linux 2, optimised for EKS workloads |
| Endpoint Access | Public | Enables kubectl access from developer workstations |
| EBS CSI Driver | Auto-installed addon | Required for PersistentVolumeClaims backed by EBS volumes |

The managed node group is configured with a minimum of one and a maximum of two `t3.medium` instances. The desired count is set to two, ensuring that the cluster can tolerate the failure of a single node while maintaining application availability. The `AmazonEBSCSIDriverPolicy` is attached to the node IAM role, granting the necessary permissions for the EBS CSI driver to create, attach, and detach EBS volumes on behalf of pods.

```
[Figure 4: EKS Cluster and Node Groups]
```
*Screenshot: AWS EKS console showing the `devops-final-cluster` with 2 active nodes and status "Active".*

### 2.4 Jenkins CI/CD Server

As a bonus feature, a dedicated EC2 instance hosts a self-managed Jenkins server. This server operates independently of the GitHub Actions pipeline and provides an alternative CI/CD platform for code quality verification.

**Table 6: Jenkins CI/CD Server Parameters**

| Parameter | Value |
|-----------|-------|
| Instance Type | `t3.small` (2 vCPU, 2 GiB RAM) |
| Operating System | Ubuntu 22.04 LTS (Jammy Jellyfish) |
| Subnet Placement | Public subnet (for HTTPS accessibility) |
| Storage | 20 GB gp3 EBS root volume |
| Public IP | Static Elastic IP (persists across instance restarts) |
| SSH Authentication | RSA-4096 key pair, auto-generated by Terraform TLS provider |

The security group for the Jenkins server permits inbound traffic on ports 22 (SSH), 80 (HTTP), 443 (HTTPS), and 8080 (Jenkins direct access). All outbound traffic is allowed. The user-data script (`jenkins-setup.sh`) automates the initial configuration by performing system updates, installing Docker, deploying the Jenkins LTS container with a persistent volume, configuring Nginx as a reverse proxy for the `jenkins.moteo.fun` domain, and installing Certbot for automated SSL certificate management.

```
[Figure 5: Jenkins Server on EC2 — AWS Console]
```
*Screenshot: AWS EC2 console showing the Jenkins instance with its Elastic IP and security group rules.*

### 2.5 Domain Name and HTTPS Configuration

The system is accessible through the registered domain `moteo.fun`, which is managed through Hostinger's DNS service. Two DNS records are configured to route traffic to the appropriate infrastructure components.

**Table 7: DNS Records**

| Subdomain | Record Type | Target | Purpose |
|-----------|------------|--------|---------|
| `www.moteo.fun` | CNAME | AWS ELB hostname of NGINX Ingress Controller | Production application access |
| `staging.moteo.fun` | CNAME | AWS ELB hostname of NGINX Ingress Controller | Staging application access |
| `jenkins.moteo.fun` | A | Elastic IP of Jenkins EC2 instance | Self-hosted CI/CD access |

HTTPS for the production application is managed internally within the Kubernetes cluster using Cert-Manager and Let's Encrypt. A ClusterIssuer resource is configured with the ACME HTTP-01 challenge type, which automatically provisions and renews TLS certificates. The issued certificate is stored as a Kubernetes Secret (`moteo-tls-secret`) and referenced by the Ingress resource. HTTPS for the Jenkins server is managed separately using Certbot running on the EC2 instance, which configures Nginx to terminate TLS and proxy requests to the Jenkins container.

```
[Figure 6: Hostinger DNS Records]
```
*Screenshot: Hostinger DNS zone editor showing CNAME records for `www.moteo.fun` and `staging.moteo.fun`, plus the A record for `jenkins.moteo.fun`.*

### 2.6 Security Considerations

Several security measures are implemented throughout the infrastructure. SSH private keys generated by Terraform are excluded from version control through the `.gitignore` file. Terraform state files, which may contain sensitive information, are also excluded from the repository. No hard-coded secrets appear in any configuration file; AWS credentials are stored as encrypted secrets within GitHub Actions. Within the application container, the process runs as a non-root user (`appuser`) rather than the default root user, following the principle of least privilege.

```
[Figure 7: GitHub Secrets Configuration]
```
*Screenshot: GitHub repository Settings > Secrets and variables > Actions showing the configured secrets (DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY).*

---

## Chapter 3: CI/CD Pipeline Design

### 3.1 Pipeline Architecture Overview

The project implements two complementary CI/CD systems. The primary pipeline runs on **GitHub Actions** and provides a complete end-to-end automation path from source code commit to production deployment. The secondary pipeline runs on the self-hosted **Jenkins** server and demonstrates an alternative CI platform with code quality verification capabilities. This dual-pipeline approach was chosen to demonstrate proficiency with multiple CI/CD platforms while maintaining a single source of truth for production deployments.

### 3.2 GitHub Actions Pipeline

The GitHub Actions pipeline is defined in the `.github/workflows/ci.yml` file and is triggered automatically whenever changes are pushed to the `main` branch. The pipeline is further constrained to execute only when changes affect the `application/`, `kubernetes/`, or `.github/workflows/` directories, thereby avoiding unnecessary runs for documentation or configuration changes that do not affect the deployed system.

The pipeline consists of three sequential jobs, each dependent on the successful completion of the preceding job. This structure enforces a quality gate at each stage of the delivery process.

```
[Figure 8: GitHub Actions Pipeline — Full Run Overview]
```
*Screenshot: GitHub Actions tab showing a successful pipeline run with all 3 jobs (build-and-push, deploy-staging, deploy-production) passing.*

#### Job 1: Build and Push (Continuous Integration)

The first job performs all continuous integration activities. It begins by checking out the latest source code from the repository using `actions/checkout@v4`. A Node.js 18 environment is then configured with npm caching enabled, which significantly reduces dependency installation time on subsequent runs by caching the `node_modules` directory based on the `package-lock.json` checksum.

Dependencies are installed using `npm ci`, which performs a clean, deterministic installation that respects the exact versions specified in the lock file. This approach is preferred over `npm install` because it guarantees reproducible builds across different environments and prevents accidental dependency drift.

Code quality is enforced through ESLint, which performs static analysis on the JavaScript source code. The linting stage is configured to fail the pipeline if any errors are detected, ensuring that only code meeting the project's coding standards proceeds further.

Security scanning is performed using Trivy, an open-source vulnerability scanner from Aqua Security. The scan operates on the filesystem of the application directory and is configured to fail the pipeline if any CRITICAL or HIGH severity vulnerabilities are detected. Unfixed vulnerabilities are ignored to focus on actionable findings. This stage fulfils the DevSecOps requirement of integrating security early in the delivery pipeline.

Following successful validation, the pipeline authenticates to Docker Hub using credentials stored as GitHub Secrets. A version tag is generated from the short Git commit SHA using `git rev-parse --short HEAD`, ensuring that every image is uniquely identifiable and traceable to its source code. The Docker image is then built using a multi-stage Dockerfile and pushed to the Docker Hub registry with this explicit version tag. The `latest` tag is deliberately never used, in accordance with the project's standard rule for image versioning.

```
[Figure 9: CI Job — Expanded Steps]
```
*Screenshot: GitHub Actions showing the expanded build-and-push job with each step (Checkout, Setup Node.js, npm ci, ESLint, Trivy, Docker Build & Push) passing.*

```
[Figure 10: Trivy Security Scan Output]
```
*Screenshot: Trivy scan results showing 0 CRITICAL, 0 HIGH vulnerabilities with the summary table.*

```
[Figure 11: Docker Hub Registry — Version-Tagged Images]
```
*Screenshot: Docker Hub repository page showing multiple image tags, each corresponding to a Git commit SHA (no 'latest' tag).*

#### Job 2: Deploy to Staging (Automatic Deployment)

Upon successful completion of the CI job, the second job automatically deploys the validated image to the staging environment. This job configures AWS credentials and connects kubectl to the EKS cluster. It then applies the staging namespace, deployment, and service manifests after replacing the `IMAGE_TAG_PLACEHOLDER` with the current Git commit SHA.

The staging environment is exposed publicly through `https://staging.moteo.fun` using the same NGINX Ingress Controller as production, with host-based routing to the staging namespace. It does not deploy its own MongoDB instance. Instead, it connects to the production MongoDB instance using Kubernetes cross-namespace DNS resolution (`mongodb-service.production.svc.cluster.local`) and uses a separate database (`products_db_staging`) to maintain data isolation. This design decision reduces resource consumption in the student environment while still providing a functionally complete staging environment.

After applying the manifests, the pipeline waits for the deployment rollout to complete with a 120-second timeout. This ensures that the staging environment is fully operational before proceeding.

```
[Figure 12: Staging Deployment Job]
```
*Screenshot: GitHub Actions showing the deploy-staging job with kubectl apply commands and rollout status.*

#### Job 3: Deploy to Production (Manual Approval with Automated Rollback)

The third job deploys the validated image to the production environment, but only after receiving manual approval. This approval gate is implemented through GitHub Environments, where the `production` environment is configured with a required reviewer. The pipeline pauses at this stage and displays an approval prompt in the GitHub Actions interface. Only after a designated team member approves the deployment does the pipeline proceed.

This manual approval gate represents a critical safety control. It ensures that a human operator has the opportunity to review the changes and verify the staging deployment before exposing the new version to production users. The trade-off is a slight delay in the deployment process, which is considered acceptable given the increased safety it provides.

Once approved, the production deployment proceeds similarly to the staging deployment, with the addition of MongoDB and HPA resources. After applying the manifests, the pipeline performs a health check by monitoring the rollout status. If the rollout succeeds within the 120-second timeout, the pipeline completes successfully. If the rollout fails, the pipeline automatically executes `kubectl rollout undo` to revert to the previous stable version, then exits with a failure code to notify the team. This automated rollback mechanism provides a safety net against faulty deployments and minimises the duration of any service disruption.

```
[Figure 13: Manual Approval Gate — GitHub Environments]
```
*Screenshot: GitHub Actions showing the "Review required" prompt waiting for approval before deploying to production.*

```
[Figure 14: Automated Rollback on Health Check Failure]
```
*Screenshot: GitHub Actions output showing the rollback sequence — "[FAIL] Production deployment failed! Rolling back..." followed by `kubectl rollout undo` and "[OK] Rollback to previous version completed."*

### 3.3 Jenkins Pipeline

The self-hosted Jenkins server runs a complementary CI pipeline defined in the `Jenkinsfile` at the repository root. This pipeline is configured as a "Pipeline script from SCM" job, which automatically fetches the pipeline definition from the GitHub repository on each execution.

The Jenkins pipeline consists of multiple stages: **Checkout**, **Install Node.js and Dependencies**, **Lint**, **Security Scan**, **Docker Build & Push**, **Deploy to Staging**, **Approve Production Deployment**, **Deploy to Production**, and **Smoke Test & Auto Rollback**.

```
[Figure 15: Jenkins Pipeline — Full Run]
```
*Screenshot: Jenkins web UI showing the `devops-final` pipeline with all stages passing (blue) or the full pipeline view.*

```
[Figure 16: Jenkins Pipeline — Stage View]
```
*Screenshot: Jenkins Stage View showing each stage with its execution time and status.*

### 3.4 Docker Image Build Strategy

The Dockerfile implements a multi-stage build pattern that separates the dependency installation phase from the runtime phase. This approach offers several advantages over a single-stage build.

```
[Figure 17: Multi-Stage Docker Build Process]
```
*Screenshot: Terminal showing the Docker build output with the two stages (builder and final) and the final image size.*

In the first stage, designated as `builder`, the official `node:18-alpine` image is used as the base. The `package.json` and `package-lock.json` files are copied first to leverage Docker's layer caching mechanism, which prevents unnecessary dependency reinstallation when only source code changes. Dependencies are installed using `npm ci --only=production`, which excludes development dependencies such as testing frameworks and linting tools.

In the second stage, a fresh `node:18-alpine` image serves as the runtime base. A non-root user and group (`appuser:appgroup`) are created to enhance container security. The pre-installed `node_modules` directory is copied from the builder stage, followed by the application source code. The working directory is assigned to the non-root user, and the container is configured to listen on port 3000.

This multi-stage approach reduces the final image size by excluding build tools, intermediate files, and development dependencies from the production image. It also improves security by minimising the attack surface of the running container.

---

## Chapter 4: Deployment and Orchestration

### 4.1 Multi-Environment Architecture

The system implements two logically isolated environments using Kubernetes namespaces. This separation allows the team to validate changes in a safe staging environment before promoting them to production, reducing the risk of introducing defects into the live system.

**Table 8: Multi-Environment Architecture Comparison**

| Aspect | Staging | Production |
|--------|---------|------------|
| Namespace | `staging` | `production` |
| Replica Count | 1 | 2 (minimum), 5 (maximum via HPA) |
| Service Type | ClusterIP (internal only) | ClusterIP (external access via NGINX Ingress) |
| Deployment Trigger | Automatic (after CI passes) | Manual approval required |
| Domain Access | `staging.moteo.fun` (HTTPS) | `www.moteo.fun` (HTTPS) |
| Resource Requests | 100m CPU, 128 MiB RAM | 100m CPU, 128 MiB RAM |
| Resource Limits | 250m CPU, 256 MiB RAM | 250m CPU, 256 MiB RAM |

The staging environment runs a single replica with minimal resource allocation, which is sufficient for validation purposes while minimising infrastructure cost. The production environment runs a minimum of two replicas to provide redundancy and can scale up to five replicas under load.

```
[Figure 18: Kubernetes Namespaces — Staging and Production]
```
*Screenshot: `kubectl get namespaces` output showing `staging` and `production` namespaces.*

### 4.2 Deployment Strategy: Rolling Updates

Both environments employ the RollingUpdate deployment strategy, which ensures zero-downtime deployments by gradually replacing pods rather than terminating all old pods before creating new ones. The strategy is configured with `maxUnavailable: 0` and `maxSurge: 1`.

The `maxUnavailable: 0` setting guarantees that the number of available pods never drops below the desired replica count during a deployment. This is achieved by creating a new pod with the updated image before terminating an old pod. The `maxSurge: 1` setting limits the number of additional pods that can be created above the desired count, preventing resource exhaustion during the update process.

Readiness probes complement the rolling update strategy by ensuring that traffic is only routed to pods that are ready to serve requests. Each probe performs an HTTP GET request to the `/health` endpoint on port 3000. The probe begins after an initial delay of 10 seconds, checks every 5 seconds, and considers the pod unhealthy after three consecutive failures. This configuration ensures that newly created pods are fully initialised before they receive traffic, and that unhealthy pods are automatically removed from the service's endpoint list.

```
[Figure 19: Deployment YAML — RollingUpdate Configuration]
```
*Screenshot: The deployment.yaml file showing the RollingUpdate strategy with maxUnavailable: 0 and maxSurge: 1, plus the readiness probe configuration.*

### 4.3 Horizontal Pod Autoscaling

The production environment is configured with a HorizontalPodAutoscaler (HPA) using the `autoscaling/v2` API version. The HPA monitors both CPU and memory utilisation and adjusts the replica count within a configured range.

**Table 9: HPA Metrics Configuration**

| Metric | Target Utilisation | Scaling Direction |
|--------|-------------------|-------------------|
| CPU | 60% of requested limit | Scale up when exceeded |
| Memory | 70% of requested limit | Scale up when exceeded |
| Minimum Replicas | 2 | Ensures baseline availability |
| Maximum Replicas | 5 | Prevents uncontrolled scaling |

The HPA operates by periodically querying the Kubernetes Metrics Server for resource utilisation data. When the average CPU or memory utilisation across all pods exceeds the configured target, the HPA increases the replica count. When utilisation drops below the target, the HPA decreases the replica count, subject to the configured minimum.

A notable operational consideration is that the Kubernetes Metrics Server is not installed by default on Amazon EKS. It must be installed separately after cluster creation using the command `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`. Without this component, the HPA reports `<unknown>` for all metric targets and cannot make scaling decisions.

```
[Figure 20: HPA Status — Scaling from 2 to 5 Pods]
```
*Screenshot: `kubectl get hpa -n production -w` showing the HPA scaling up from 2 to 5 replicas under load.*

```
[Figure 21: HPA YAML Configuration]
```
*Screenshot: The hpa.yaml file showing the autoscaling/v2 API with CPU target of 60% and memory target of 70%.*

### 4.4 Ingress and TLS Configuration

External access to the production application is managed through the NGINX Ingress Controller, which is deployed in the `ingress-nginx` namespace. The Ingress Controller is exposed externally through an AWS Elastic Load Balancer (ELB) of type `LoadBalancer`, which is the only load balancer in the entire architecture.

A deliberate design decision was made to configure the application's Kubernetes Service (`devops-final-service`) with `type: ClusterIP` rather than `type: LoadBalancer`. This prevents the creation of a redundant, insecure second AWS ELB that would bypass the Ingress Controller's TLS termination. All external traffic enters exclusively through the single NGINX Ingress Controller, which terminates TLS using a Let's Encrypt certificate and routes requests to the appropriate backend service.

```
[Figure 22: Ingress Traffic Flow Diagram]
```
*Screenshot: Diagram showing traffic flow: User → www.moteo.fun → AWS ELB → NGINX Ingress Controller → Service (ClusterIP) → Pods.*

TLS certificates are managed automatically by Cert-Manager, which is installed in the `cert-manager` namespace. A ClusterIssuer resource is configured to use the Let's Encrypt ACME production server with the HTTP-01 challenge type. The Ingress resource references this ClusterIssuer through the `cert-manager.io/cluster-issuer` annotation and specifies the TLS configuration for the `www.moteo.fun` domain. The issued certificate is stored as a Kubernetes Secret named `moteo-tls-secret` and is automatically renewed by Cert-Manager before expiration.

```
[Figure 23: TLS Certificate — Let's Encrypt via Cert-Manager]
```
*Screenshot: `kubectl get certificate -n production` showing READY=True, plus the browser padlock icon showing "Connection is secure".*

### 4.5 Self-Healing Behaviour

Kubernetes provides automatic self-healing capabilities through its controller architecture. The ReplicaSet controller continuously monitors the state of pods and ensures that the desired number of replicas is maintained at all times. If a pod is terminated, whether due to a node failure, resource exhaustion, or manual deletion, the ReplicaSet controller detects the discrepancy and creates a replacement pod.

This self-healing behaviour was verified through a controlled failure simulation. A running pod in the production namespace was manually deleted using the `kubectl delete pod` command. Within approximately five seconds, the ReplicaSet controller created a new pod, which transitioned through the `Pending` and `ContainerCreating` states before reaching `Running` status. The new pod was automatically added to the service's endpoint list once its readiness probe succeeded, restoring full service capacity without any manual intervention.

```
[Figure 24: Self-Healing — Pod Deletion and Automatic Recovery]
```
*Screenshot: Terminal showing `kubectl delete pod` followed by `kubectl get pods -n production -w` showing the old pod terminating and a new pod being created automatically.*

### 4.6 Persistent Storage with AWS S3

A significant architectural challenge arose from the ephemeral nature of Kubernetes pod storage. Because the application runs with multiple replicas and pods can be terminated and recreated at any time, storing uploaded images on the local filesystem would result in data loss and inconsistency across replicas.

The solution to this challenge was to store product images directly in AWS S3, which provides durable, highly available, and shareable object storage. The upload process uses the `multer-s3` middleware, which streams uploaded files directly from the HTTP request to S3 without intermediate storage on the pod's filesystem. The resulting S3 URL is stored in the database as the image reference, and browsers load images directly from S3 rather than proxying through the application server.

The S3 bucket (`devops-final-uploads-dqc28664`) is provisioned by Terraform in `infrastructure/s3.tf`. A bucket policy grants public read access to objects under the `uploads/` prefix, enabling browsers to load images without authentication. An IAM policy attached to the EKS node role grants the necessary S3 permissions (`s3:PutObject`, `s3:GetObject`, `s3:DeleteObject`) to the application pods. The bucket name and AWS region are injected into the pods through environment variables defined in the deployment manifest.

```
[Figure 25: AWS S3 Bucket — Uploaded Product Images]
```
*Screenshot: AWS S3 console showing the `devops-final-uploads-dqc28664` bucket with uploaded images under the `uploads/` prefix.*

### 4.7 Kubernetes Manifest Summary

The following table enumerates all Kubernetes manifests used in the project, organised by namespace and purpose.

**Table 10: Kubernetes Manifest Summary**

| Manifest | Namespace | Purpose |
|----------|-----------|---------|
| `staging/namespace.yaml` | — | Creates the `staging` namespace |
| `staging/deployment.yaml` | staging | Single-replica deployment with readiness probe |
| `staging/service.yaml` | staging | ClusterIP service (port 80 to 3000) |
| `staging/ingress-ssl.yaml` | staging | HTTPS Ingress for `staging.moteo.fun` |
| `production/namespace.yaml` | — | Creates the `production` namespace |
| `deployment.yaml` | production | Two-replica deployment with RollingUpdate strategy |
| `service.yaml` | production | ClusterIP service (port 80 to 3000, internal only) |
| `hpa.yaml` | production | HPA: 2 to 5 pods, CPU 60%, memory 70% |
| `mongodb-pvc.yaml` | production | PersistentVolumeClaim of 1 GiB for MongoDB data |
| `mongodb-deployment.yaml` | production | MongoDB pod with persistent storage |
| `mongodb-service.yaml` | production | ClusterIP service exposing MongoDB on port 27017 |
| `ingress-ssl.yaml` | production | NGINX Ingress with Let's Encrypt TLS |
| `alerting-rules.yaml` | monitoring | Four PrometheusRule alerts for production |
| `prometheus-scrape.yaml` | monitoring | ServiceMonitor for Prometheus auto-discovery |

```
[Figure 26: All Running Pods Across Namespaces]
```
*Screenshot: `kubectl get pods -A` showing all pods running across production, staging, ingress-nginx, cert-manager, and monitoring namespaces.*

---

## Chapter 5: Monitoring, Observability, and Lessons Learned

### 5.1 Monitoring Stack Architecture

The observability layer is deployed using the **kube-prometheus-stack** Helm chart, which bundles several complementary components into a cohesive monitoring solution. This stack is installed in the `monitoring` namespace and provides comprehensive visibility into both infrastructure and application health.

**Table 11: Monitoring Stack Components**

| Component | Purpose |
|-----------|---------|
| Prometheus | Time-series metrics collection, storage, and querying |
| Grafana | Dashboard visualisation and alert management interface |
| Alertmanager | Alert routing, grouping, deduplication, and notification |
| kube-state-metrics | Exports Kubernetes object state as Prometheus metrics |
| node-exporter | Exports host-level system metrics from each node |

The decision to use the kube-prometheus-stack rather than installing each component individually was driven by the tight integration between these components. The stack automatically configures Prometheus to discover and scrape metrics from Kubernetes components, configures Grafana with pre-built dashboards for Kubernetes monitoring, and sets up Alertmanager with sensible default routing rules. This integrated approach significantly reduces configuration effort while providing a production-grade monitoring foundation.

```
[Figure 27: Monitoring Stack Pods]
```
*Screenshot: `kubectl get pods -n monitoring` showing Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter pods all running.*

### 5.2 Grafana Dashboards

Grafana is deployed as part of the kube-prometheus-stack and is accessible through port-forwarding from the local workstation. The built-in Kubernetes dashboards provide real-time visibility into several dimensions of system health.

CPU usage is displayed per pod and per node, allowing the team to identify resource-intensive components and verify the correct operation of the Horizontal Pod Autoscaler. Memory usage is similarly visualised, showing working set consumption by container and node. Pod status dashboards track the count of running, pending, failed, and restarting pods, providing immediate awareness of any deployment issues. Network I/O charts show ingress and egress traffic patterns, which can help identify traffic anomalies or scaling triggers.

These dashboards reflect the actual production system and are updated in real time as metrics are scraped by Prometheus every 15 seconds. During the demonstration, the team opens the Grafana interface and explains how each metric corresponds to the current state of the deployed system.

```
[Figure 28: Grafana Dashboard — Kubernetes Compute Resources / Pod]
```
*Screenshot: Grafana dashboard showing real-time CPU usage, memory usage, and pod status for the production namespace.*

```
[Figure 29: Grafana Dashboard — Kubernetes / Networking]
```
*Screenshot: Grafana dashboard showing network I/O charts for the production pods.*

### 5.3 Custom Alerting Rules

Four custom PrometheusRule alerts are configured for the production namespace. These alerts are defined in the `kubernetes/alerting-rules.yaml` manifest and are automatically loaded by Prometheus through the Prometheus Operator's custom resource definitions.

**Table 12: Custom Alerting Rules**

| Alert Name | Expression | Severity | Duration |
|-----------|-----------|----------|----------|
| PodCrashLooping | `rate(kube_pod_container_status_restarts_total{namespace="production"}[5m]) > 0` | Critical | 2 minutes |
| HighCPUUsage | CPU usage exceeds 80% of resource limits | Warning | 3 minutes |
| HighMemoryUsage | Memory usage exceeds 85% of resource limits | Warning | 3 minutes |
| DeploymentReplicasMismatch | Available replicas are fewer than desired replicas | Critical | 1 minute |

The **PodCrashLooping** alert fires when any pod in the production namespace has restarted more than zero times within a five-minute window. This detects situations where a pod is stuck in a crash loop, such as when the application fails to start due to a configuration error or missing dependency.

The **HighCPUUsage** and **HighMemoryUsage** alerts fire when resource consumption approaches the configured limits. These alerts serve as early warning signals that the Horizontal Pod Autoscaler may need to scale up, or that resource limits may need adjustment.

The **DeploymentReplicasMismatch** alert fires when the number of available replicas is less than the desired replica count. This can occur during a failed deployment, a node failure, or when pods are unable to start due to resource constraints. This alert is configured with a shorter evaluation duration (1 minute) because it indicates an immediate availability concern.

```
[Figure 30: Alertmanager — Fired Alerts]
```
*Screenshot: Alertmanager web UI (port-forwarded to localhost:9093) showing the DeploymentReplicasMismatch alert firing after pod deletion.*

```
[Figure 31: Alerting Rules YAML — PrometheusRule]
```
*Screenshot: The alerting-rules.yaml file showing all four PrometheusRule alert definitions.*

### 5.4 Centralised Logging with Loki and Promtail

To complement Prometheus metrics with log-based observability, the system includes Grafana Loki for log aggregation and Promtail for log collection. Both components are deployed using the `grafana/loki-stack` Helm chart, which is configured through the `kubernetes/loki-values.yaml` values file.

Loki operates in single-binary mode, which is appropriate for the scale of this project. It stores logs with a retention period of seven days (168 hours), after which older logs are automatically deleted. Promtail runs as a DaemonSet on each Kubernetes node, collecting container logs from the CRI (Container Runtime Interface) log directory and forwarding them to Loki.

The decision to reuse the existing Grafana instance from the kube-prometheus-stack rather than deploying a separate Grafana for Loki was a deliberate optimisation. Both data sources are accessible from the same Grafana interface, allowing the team to correlate metrics and logs in a single view. In the Grafana Explore view, users can select Loki as the data source and query logs using LogQL, Prometheus's log-based query language.

Commonly used LogQL queries include filtering logs by namespace (`{namespace="production"}`), searching for error messages (`{namespace="production"} |= "error"`), and parsing JSON-structured logs (`{namespace="production"} | json | level="error"`).

```
[Figure 32: Grafana Explore — Loki Log Queries]
```
*Screenshot: Grafana Explore view with Loki selected as data source, showing log lines from the production namespace filtered by LogQL query.*

### 5.5 Custom Application-Level Metrics

Beyond infrastructure-level metrics, the application itself exposes business-level metrics through the `prom-client` library, which is the official Prometheus client for Node.js. These metrics are implemented in a dedicated `metrics.js` module that is imported by the application's entry point (`main.js`).

Five custom metrics are defined, each serving a specific observability purpose:

The **`moteo_http_requests_total`** counter tracks the total number of HTTP requests received, labelled by HTTP method, route path, and response status code. This metric enables the team to monitor request volumes and error rates over time.

The **`moteo_http_request_duration_ms`** histogram measures request processing time in milliseconds, labelled by the same dimensions. This metric supports latency analysis, including percentile calculations such as p95 and p99 response times.

The **`moteo_http_active_requests`** gauge tracks the number of requests currently being processed. This metric provides insight into concurrent request handling and can indicate when the application is approaching its capacity limits.

The **`moteo_product_operations_total`** counter tracks product CRUD operations, labelled by operation type (create, read, update, delete) and status (success, error). This metric provides business-level visibility into how users are interacting with the application.

The **`moteo_file_uploads_total`** counter tracks S3 image uploads, labelled by status. This metric helps monitor the file upload functionality and detect upload failures.

These metrics are exposed at the `/metrics` endpoint, which is scraped by Prometheus every 15 seconds through a ServiceMonitor custom resource. The ServiceMonitor is configured to match the `app: devops-final-app` label on the application's Kubernetes Service, ensuring automatic discovery without manual configuration.

```
[Figure 33: Custom Application Metrics — /metrics Endpoint]
```
*Screenshot: `curl http://localhost:8080/metrics` showing the custom prom-client metrics (moteo_http_requests_total, moteo_http_request_duration_ms, moteo_http_active_requests, moteo_product_operations_total, moteo_file_uploads_total).*

```
[Figure 34: ServiceMonitor YAML — Prometheus Auto-Discovery]
```
*Screenshot: The prometheus-scrape.yaml file showing the ServiceMonitor configuration that enables Prometheus to automatically scrape the /metrics endpoint.*

### 5.6 Lessons Learned

Throughout the development and operation of this system, the team encountered several challenges that yielded valuable insights.

**EKS Metrics Server Requirement**: Amazon EKS does not include the Kubernetes Metrics Server by default. Without this component, the Horizontal Pod Autoscaler cannot obtain CPU and memory utilisation data and reports `<unknown>` for all metric targets. This component must be installed separately after cluster creation, which is an easily overlooked step when transitioning from local Kubernetes environments such as Minikube.

**Docker-in-Docker Limitations**: Running Docker commands inside a Jenkins container requires either Docker-in-Docker (DinD) or mounting the host's Docker socket. Both approaches introduce complexity and security concerns. The team opted to use NVM-based Node.js installation within the Jenkins pipeline instead, which proved simpler and more reliable for the CI requirements of this project.

**Terraform Destroy Order**: LoadBalancer-type Kubernetes Services create AWS Elastic Load Balancers with associated Elastic Network Interfaces (ENIs). These resources must be cleaned up by deleting Helm releases and namespaces before running `terraform destroy`. Failure to do so results in `DependencyViolation` errors during VPC and subnet deletion. The destroy script (`destroy.ps1`) incorporates a 90-second wait after Helm uninstallation to allow AWS to release these resources.

**DNS Propagation Delay**: After infrastructure recreation, all Load Balancer endpoints change. DNS records on the domain registrar (Hostinger) must be updated with new CNAME and A values. Propagation can take between one and five minutes, during which the system may be intermittently accessible. The deployment script (`deploy.ps1`) includes a polling loop that waits for DNS propagation before proceeding with HTTPS configuration.

**Cost Management**: The complete infrastructure, including the EKS cluster with two t3.medium worker nodes, the Jenkins t3.small EC2 instance, the NAT Gateway, and Elastic IPs, incurs ongoing AWS charges. A systematic provisioning and teardown procedure was documented in `Guiding_light.md` to enable on-demand infrastructure lifecycle management, allowing the team to destroy resources when not in use and recreate them when needed.

**Multi-Stage Docker Builds**: Separating the dependency installation stage from the runtime stage significantly reduces the final image size and improves security. The builder stage contains development tools and intermediate files that are excluded from the final image, reducing both storage requirements and the potential attack surface.

**GitHub Environment Protection Rules**: Configuring required reviewers on the GitHub `production` environment provides a critical safety gate. This feature prevents untested code from reaching production without human verification, even if the pipeline is triggered automatically. The trade-off is a slight delay in the deployment process, which is justified by the increased confidence it provides.

```
[Figure 35: GitHub Environment Protection — Production Reviewer]
```
*Screenshot: GitHub Settings > Environments > production showing the required reviewer configuration.*

```
[Figure 36: GitHub Contributors — Team Members]
```
*Screenshot: GitHub Insights > Contributors showing the three team members and their commit activity.*

```
[Figure 37: Deploy Script Execution — deploy.ps1 Output]
```
*Screenshot: Terminal showing the deploy.ps1 script running through its 8 steps (Terraform, Helm, K8s manifests, DNS pause).*

```
[Figure 38: Destroy Script Execution — destroy.ps1 Output]
```
*Screenshot: Terminal showing the destroy.ps1 script running through Helm uninstall, 90s LB wait, K8s cleanup, and terraform destroy.*

```
[Figure 39: Setup Script — setup.sh Execution]
```
*Screenshot: Terminal showing setup.sh installing AWS CLI, Terraform, kubectl, Helm, Docker, and Node.js on a fresh EC2 instance.*

```
[Figure 40: Stress Test — HPA Scaling Demonstration]
```
*Screenshot: Terminal running `node stress-test.js 200 https://www.moteo.fun` showing RPS, latency, and error stats, alongside `kubectl get hpa -n production -w` showing scaling from 2 to 5 pods.*

---

## Supporting Links

**Table 13: Supporting Links**

| Resource | URL | Description |
|----------|-----|-------------|
| GitHub Repository | [https://github.com/DinhQuocCuong28664/DevOps_Final_Project](https://github.com/DinhQuocCuong28664/DevOps_Final_Project) | Source code, infrastructure definitions, pipeline configurations, and documentation |
| Docker Hub Registry | [https://hub.docker.com/r/dinhquoccuong286/devops-final-app](https://hub.docker.com/r/dinhquoccuong286/devops-final-app) | Container images tagged with explicit Git commit SHA |
| Production Website | [https://www.moteo.fun](https://www.moteo.fun) | Live production application with HTTPS |
| Staging Website | [https://staging.moteo.fun](https://staging.moteo.fun) | Live staging application with HTTPS |
| Jenkins CI/CD | [https://jenkins.moteo.fun](https://jenkins.moteo.fun) | Self-hosted Jenkins server |
| Video Demonstration | [Video Demonstration Link — placeholder] | End-to-end walkthrough following the mandatory demo scenario |

---

## References

[1] HashiCorp, "Terraform Documentation," 2024. [Online]. Available: https://developer.hashicorp.com/terraform/docs

[2] Amazon Web Services, "Amazon EKS User Guide," 2024. [Online]. Available: https://docs.aws.amazon.com/eks/latest/userguide/

[3] The Kubernetes Authors, "Kubernetes Documentation," 2024. [Online]. Available: https://kubernetes.io/docs/

[4] Docker Inc., "Docker Documentation," 2024. [Online]. Available: https://docs.docker.com/

[5] Prometheus Authors, "Prometheus Documentation," 2024. [Online]. Available: https://prometheus.io/docs/

[6] Grafana Labs, "Grafana Documentation," 2024. [Online]. Available: https://grafana.com/docs/

[7] Grafana Labs, "Loki Documentation," 2024. [Online]. Available: https://grafana.com/docs/loki/

[8] The Linux Foundation, "Helm Documentation," 2024. [Online]. Available: https://helm.sh/docs/

[9] Cert-Manager Contributors, "Cert-Manager Documentation," 2024. [Online]. Available: https://cert-manager.io/docs/

[10] Let's Encrypt, "Let's Encrypt Documentation," 2024. [Online]. Available: https://letsencrypt.org/docs/

[11] OpenJS Foundation, "Node.js Documentation," 2024. [Online]. Available: https://nodejs.org/en/docs/

[12] Express.js Contributors, "Express.js Documentation," 2024. [Online]. Available: https://expressjs.com/

[13] MongoDB Inc., "MongoDB Documentation," 2024. [Online]. Available: https://www.mongodb.com/docs/

[14] Aqua Security, "Trivy Documentation," 2024. [Online]. Available: https://trivy.dev/

[15] ESLint Contributors, "ESLint Documentation," 2024. [Online]. Available: https://eslint.org/docs/

[16] GitHub, "GitHub Actions Documentation," 2024. [Online]. Available: https://docs.github.com/en/actions

[17] Jenkins Project, "Jenkins Documentation," 2024. [Online]. Available: https://www.jenkins.io/doc/

[18] NGINX Inc., "NGINX Ingress Controller Documentation," 2024. [Online]. Available: https://kubernetes.github.io/ingress-nginx/

[19] Prometheus Contributors, "prom-client: Prometheus Client for Node.js," 2024. [Online]. Available: https://github.com/siimon/prom-client

[20] Amazon Web Services, "AWS SDK for JavaScript v3 Documentation," 2024. [Online]. Available: https://docs.aws.amazon.com/AWSJavaScriptSDK/v3/latest/

---

*End of Technical Report*
