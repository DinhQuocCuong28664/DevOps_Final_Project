# Presentation Script: Production-Grade CI/CD System for Startup X

**Target duration:** 12-15 minutes  
**Project tier:** Tier 5 - Expert Kubernetes-Based Architecture on Amazon EKS  
**Production URL:** https://www.moteo.fun  
**Jenkins URL:** https://jenkins.moteo.fun

## Slide 1 - Title

**Timing:** 45 seconds

**Speaking script:**

Good morning/afternoon. We are presenting our final project, **Production-Grade CI/CD System for Startup X**. This project implements a Tier 5 Kubernetes-based deployment on Amazon EKS with automated CI/CD, infrastructure as code, HTTPS, monitoring, alerting, and centralized logging.

Our team members are Đinh Quốc Cường, Nguyễn Quang Trường, and Phạm Minh Hào. The system is deployed publicly at `https://www.moteo.fun`, and our self-hosted Jenkins service is available at `https://jenkins.moteo.fun`.

The main objective was not only to deploy a web application, but to build an operationally mature delivery system that is reproducible, secure, scalable, observable, and aligned with production DevOps practices.

**Technical points to mention:**

- Course: Software Deployment, Operations & Maintenance.
- Assessment: Final Exam Project.
- Architecture tier: Tier 5, Amazon EKS.
- Application: Node.js/Express web platform with MongoDB and S3 image uploads.

## Slide 2 - Project Goals and Grading Alignment

**Timing:** 1 minute

**Speaking script:**

The project specification requires a production-grade delivery system covering infrastructure provisioning, CI/CD automation, secure deployment, and observability. We aligned the implementation with the official checklist.

For infrastructure, we used AWS as the cloud provider, Terraform for Infrastructure as Code, a registered domain, and Let's Encrypt HTTPS. For CI, we implemented linting, npm dependency caching, Trivy vulnerability scanning, Docker image builds, and commit-SHA image tagging. For CD, the pipeline deploys automatically to staging, then requires manual approval before production deployment. For deployment, we used Kubernetes Deployments, Services, Ingress, rolling updates, HPA autoscaling, and self-healing. For observability, we deployed Prometheus, Grafana, Alertmanager, Loki, Promtail, and custom application metrics.

This slide is important because the grading note says that implemented features count only if they are shown and clearly explained. During the presentation and demo, we therefore explicitly show the core checklist items.

**Talking points:**

- Public cloud: AWS.
- Domain and HTTPS: `www.moteo.fun` with Cert-Manager and Let's Encrypt.
- CI requirements: lint, cache, build, scan, versioned Docker image.
- CD requirements: staged rollout, production approval, controlled deployment.
- Observability requirements: CPU, memory, pod status, logs, alerts.

## Slide 3 - Architecture Overview: Tier 5 on Amazon EKS

**Timing:** 1 minute 15 seconds

**Speaking script:**

We selected Tier 5 because Kubernetes best matches the production requirements of Startup X. The architecture is divided into four main domains.

First, the development and CI/CD domain consists of GitHub, GitHub Actions, and Jenkins. Second, the container registry domain uses Docker Hub to store immutable, version-tagged images. Third, the AWS infrastructure domain contains the VPC, EKS cluster, private worker nodes, Jenkins EC2 instance, S3 bucket, and load balancer created by the NGINX Ingress Controller. Fourth, the observability domain includes Prometheus, Grafana, Alertmanager, Loki, and Promtail.

The user traffic flow is: user accesses `www.moteo.fun`, DNS points to the AWS load balancer, the load balancer forwards traffic to NGINX Ingress, and Ingress routes to the Kubernetes Service and application pods. The pods connect to MongoDB for data and S3 for persistent uploaded images.

**Technical points to mention:**

- EKS version: Kubernetes 1.30.
- Worker nodes: managed node group with `t3.medium` nodes.
- Ingress is the only external entry point for the app.
- Application Service is `ClusterIP`, not `LoadBalancer`, to avoid bypassing TLS termination.

## Slide 4 - Infrastructure Provisioning with Terraform

**Timing:** 1 minute 15 seconds

**Speaking script:**

All AWS infrastructure is provisioned using Terraform, which makes the environment reproducible and idempotent. The configuration is split by responsibility.

The `provider.tf` file configures AWS in the Sydney region, `ap-southeast-2`. The `vpc.tf` file creates the VPC, public and private subnets, NAT Gateway, and required EKS subnet tags. The `eks.tf` file provisions the EKS cluster, managed node group, IAM roles, and EBS CSI driver addon. The `s3.tf` file creates the S3 upload bucket and grants the node role permissions for object access. The `jenkins.tf` file provisions the Jenkins EC2 instance, Elastic IP, security group, and SSH key pair.

The network uses two Availability Zones. Public subnets host internet-facing components such as the load balancer and Jenkins EC2. Private subnets host EKS worker nodes, reducing direct exposure. We used a single NAT Gateway to control cost, and we documented that a production enterprise deployment would normally use one NAT Gateway per Availability Zone for higher resilience.

**Technical points to mention:**

- VPC CIDR: `10.0.0.0/16`.
- Public subnets: `10.0.101.0/24`, `10.0.102.0/24`.
- Private subnets: `10.0.1.0/24`, `10.0.2.0/24`.
- EBS CSI driver supports MongoDB PVC.
- Terraform idempotency was verified with repeated `terraform apply` returning no changes.

## Slide 5 - CI/CD Pipeline Design

**Timing:** 1 minute 30 seconds

**Speaking script:**

The primary CI/CD system is GitHub Actions. It is triggered automatically on pushes to the `main` branch when application, Kubernetes, or workflow files change.

The pipeline has three jobs. The first job is `build-and-push`. It checks out the source code, configures Node.js 18 with npm caching, installs dependencies using `npm ci`, runs ESLint, runs Trivy security scanning, builds a Docker image, and pushes that image to Docker Hub. Every image is tagged with the short Git commit SHA. We intentionally do not rely on the `latest` tag because commit-SHA tags make deployments traceable and reproducible.

The second job deploys automatically to staging. It connects to EKS, substitutes the current image tag into the Kubernetes manifests, applies the staging deployment, and waits for rollout completion.

The third job deploys to production after manual approval through GitHub Environments. After applying production manifests, the pipeline checks rollout health. If the rollout fails, it automatically executes `kubectl rollout undo`, restoring the previous stable ReplicaSet.

**Technical points to mention:**

- CI quality gate: ESLint and Trivy must pass.
- Security gate: CRITICAL/HIGH vulnerabilities fail the pipeline.
- Deployment gate: staging automatic, production manual approval.
- Rollback command: `kubectl rollout undo deployment/devops-final-app -n production`.
- Jenkins is included as a self-hosted bonus CI/CD platform.

## Slide 6 - Deployment and Kubernetes Orchestration

**Timing:** 1 minute 30 seconds

**Speaking script:**

The application is deployed using Kubernetes manifests. We separate environments using namespaces: `staging` and `production`. Staging runs one replica and is used for validation before promotion. Production starts with two replicas and can scale to five through the Horizontal Pod Autoscaler.

The production Deployment uses a RollingUpdate strategy with `maxUnavailable: 0` and `maxSurge: 1`. This means Kubernetes creates a new pod before removing an old one, keeping the service available during deployments. Readiness probes call the `/health` endpoint, so traffic is sent only to pods that are ready.

Self-healing is provided by Kubernetes controllers. If we delete a production pod, the ReplicaSet automatically creates a replacement pod. The Service updates its endpoint list after the new pod passes readiness checks.

Autoscaling is handled by HPA using CPU and memory metrics. The HPA scales from 2 to 5 pods when CPU exceeds 60 percent of requested CPU or memory exceeds 70 percent of requested memory. A key operational detail is that EKS does not include Metrics Server by default, so we installed it separately to make HPA functional.

**Technical points to mention:**

- Namespaces: `staging`, `production`, `monitoring`, `ingress-nginx`, `cert-manager`.
- Production replicas: minimum 2, maximum 5.
- MongoDB uses PersistentVolumeClaim backed by EBS.
- S3 is used for uploaded images because pod filesystem storage is ephemeral.

## Slide 7 - Security, Domain, and HTTPS

**Timing:** 1 minute

**Speaking script:**

Security is implemented across the delivery and runtime layers. At the CI layer, Trivy scans the application filesystem and fails the pipeline for high or critical vulnerabilities. Docker images are built with a multi-stage Dockerfile and the application runs as a non-root `appuser` in the final container.

For external access, we use Hostinger DNS for the `moteo.fun` domain. The production application uses a CNAME record from `www.moteo.fun` to the AWS load balancer created by NGINX Ingress. Jenkins uses an A record from `jenkins.moteo.fun` to its Elastic IP.

HTTPS for the Kubernetes application is automated using Cert-Manager and Let's Encrypt. Cert-Manager solves the ACME HTTP-01 challenge and stores the certificate in the `moteo-tls-secret` Kubernetes Secret. Jenkins HTTPS is handled separately by Nginx and Certbot on the EC2 instance.

**Technical points to mention:**

- No secrets are hard-coded in repository files.
- GitHub Actions credentials are stored as encrypted repository secrets.
- Terraform state and private key files are excluded from Git.
- Single Ingress entry point simplifies TLS and traffic control.

## Slide 8 - Monitoring and Observability

**Timing:** 1 minute 30 seconds

**Speaking script:**

For observability, we deployed kube-prometheus-stack in the `monitoring` namespace. This gives us Prometheus for metrics, Grafana for dashboards, Alertmanager for alert routing, kube-state-metrics for Kubernetes object state, and node-exporter for node-level metrics.

Grafana dashboards show CPU usage, memory usage, pod status, node health, and network activity. These dashboards reflect the actual production namespace, not a simulated environment.

We also added custom application metrics using the Node.js `prom-client` library. The application exposes metrics at `/metrics`, and Prometheus discovers the endpoint through a ServiceMonitor. Custom metrics include HTTP request count, request duration, active requests, product CRUD operations, and S3 upload results.

For logs, we deployed Loki and Promtail. Promtail runs on each node and forwards container logs to Loki. In Grafana Explore, we can query logs using LogQL, for example `{namespace="production"}` or `{namespace="production"} |= "error"`.

**Technical points to mention:**

- Prometheus scrape interval: 15 seconds.
- Alerts: PodCrashLooping, HighCPUUsage, HighMemoryUsage, DeploymentReplicasMismatch.
- Loki retention: seven days.
- Metrics and logs are correlated in one Grafana interface.

## Slide 9 - Mandatory Demo Walkthrough

**Timing:** 1 minute 30 seconds

**Speaking script:**

The demo follows the official mandatory scenario step by step.

First, we make a visible source code change, such as modifying text in the UI. Second, we commit and push that change to the `main` branch. Third, GitHub Actions starts automatically and runs the CI stages: dependency installation with cache, ESLint, Trivy scan, Docker build, and Docker Hub push with a commit-SHA tag.

Fourth, the staging deployment runs automatically and waits for rollout success. Fifth, we approve the production deployment through the GitHub Environment approval gate. Sixth, the production deployment performs a rolling update and health check. Seventh, we open `https://www.moteo.fun` and verify that the new UI change is live over HTTPS.

After deployment validation, we open Grafana and explain CPU, memory, and pod status dashboards. Finally, we simulate failure by deleting a production pod. Kubernetes automatically recreates the pod, and we show the recovery in `kubectl`, Grafana, and Alertmanager if an alert fires.

**Demo commands to mention if needed:**

```bash
kubectl get pods -n production
kubectl rollout status deployment/devops-final-app -n production
kubectl get hpa -n production
kubectl delete pod <pod-name> -n production
kubectl get pods -n production -w
```

## Slide 10 - Lessons Learned and Trade-Offs

**Timing:** 1 minute 15 seconds

**Speaking script:**

Several lessons came from operating the system end to end.

First, EKS does not install Metrics Server by default. Without it, HPA cannot read CPU or memory metrics and shows `<unknown>`, so Metrics Server is mandatory for autoscaling.

Second, Docker-in-Docker in Jenkins introduces complexity and security concerns. For the Jenkins bonus pipeline, we kept the implementation simpler and more reliable by focusing on source checkout, dependency installation, and linting.

Third, Terraform destroy order matters. Kubernetes LoadBalancer services create AWS load balancers and ENIs. If those are not deleted before `terraform destroy`, AWS dependency violations can occur. Our destroy script removes Helm releases and Kubernetes resources first, waits for load balancer cleanup, then destroys infrastructure.

Fourth, DNS propagation can delay HTTPS setup after infrastructure recreation because load balancer endpoints change. Our deployment process accounts for this with DNS update and polling steps.

Finally, we balanced cost and availability. We used two Availability Zones and two EKS nodes for baseline resilience, but one NAT Gateway to reduce cost. We documented that a stricter production design would use NAT Gateway redundancy per AZ.

## Slide 11 - Conclusion and Q&A

**Timing:** 45 seconds

**Speaking script:**

In conclusion, this project delivers a production-grade CI/CD system for Startup X using Tier 5 Kubernetes architecture on Amazon EKS. The system includes Terraform-based infrastructure, GitHub Actions and Jenkins pipelines, Docker image security scanning and versioning, Kubernetes rolling updates, HPA autoscaling, HTTPS, monitoring, alerting, centralized logging, and automated rollback.

The implementation is aligned with the official checklist and is supported by the technical report, repository artifacts, screenshots, and live demo evidence.

We are ready for questions.

**Likely transition:**

- If asked about design choices, explain the trade-off, not just the tool name.
- If asked about evidence, point to the live URL, GitHub Actions run, Kubernetes resources, or Grafana dashboard.
- If asked about limitations, mention single NAT Gateway, single MongoDB pod, and Jenkins pipeline scope as deliberate cost and scope trade-offs.
