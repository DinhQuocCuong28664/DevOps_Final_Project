# Questions, Troubleshooting, and Implementation Notes

This file prepares the team for practical evaluator questions and common implementation issues encountered while building the Tier 5 Amazon EKS CI/CD system.

## Common Setup Issues and Solutions

### 1. EKS HPA Shows `<unknown>` Metrics

**Problem:**

`kubectl get hpa -n production` shows CPU and memory targets as `<unknown>`, and the Horizontal Pod Autoscaler does not scale pods.

**Root cause:**

Amazon EKS does not install Kubernetes Metrics Server by default. HPA depends on Metrics Server to read pod CPU and memory usage through the Kubernetes metrics API.

**Solution:**

Install Metrics Server after EKS creation:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl get deployment metrics-server -n kube-system
kubectl top pods -n production
kubectl get hpa -n production
```

**What to say in presentation:**

We learned that HPA is not enough by itself. The metrics pipeline must also exist, so installing Metrics Server is a required operational step on EKS.

### 2. Docker-in-Docker Problems in Jenkins

**Problem:**

Running Docker build commands inside Jenkins can fail with permission errors, missing Docker daemon errors, or socket access issues.

**Root cause:**

Jenkins runs inside a container. Docker commands inside a container require either Docker-in-Docker or mounting the host Docker socket. Both options add security risk and operational complexity.

**Possible solutions:**

- Mount `/var/run/docker.sock` into the Jenkins container and add the Jenkins user to the Docker group.
- Use Docker-in-Docker with a privileged container.
- Use Jenkins agents on the host or on Kubernetes.
- Keep Jenkins as a supplementary CI pipeline focused on checkout, dependency installation, and linting, while GitHub Actions performs the full build and deployment path.

**Chosen approach:**

GitHub Actions is the primary production CI/CD pipeline. Jenkins is retained as a self-hosted CI/CD bonus service and demonstrates SCM integration and code quality validation without increasing deployment risk.

### 3. Terraform Destroy Fails with `DependencyViolation`

**Problem:**

`terraform destroy` fails when deleting VPC resources, subnets, or security groups.

**Root cause:**

Kubernetes `LoadBalancer` services and Helm charts create AWS resources such as Elastic Load Balancers and Elastic Network Interfaces. AWS may still be holding those dependencies when Terraform tries to delete the VPC.

**Solution:**

Delete Kubernetes and Helm-created resources before Terraform destroy:

```bash
helm uninstall ingress-nginx -n ingress-nginx
helm uninstall prometheus -n monitoring
helm uninstall loki -n monitoring
kubectl delete namespace ingress-nginx monitoring cert-manager production staging
```

Wait for AWS load balancers and ENIs to be released, then run:

```bash
terraform destroy
```

**Project-specific mitigation:**

The `destroy.ps1` script handles cleanup order and includes a wait period so AWS can release load balancer resources.

### 4. DNS Propagation Delay After Recreating Infrastructure

**Problem:**

The application or Jenkins domain does not work immediately after redeploying infrastructure.

**Root cause:**

AWS load balancer DNS names and Jenkins Elastic IP targets can change after recreation. Hostinger DNS records must be updated, and DNS propagation takes time.

**Solution:**

- Update `www.moteo.fun` CNAME to the new AWS load balancer hostname.
- Update `jenkins.moteo.fun` A record if the Jenkins Elastic IP changes.
- Wait 1-5 minutes and verify DNS resolution.

Useful checks:

```bash
nslookup www.moteo.fun
nslookup jenkins.moteo.fun
curl -I https://www.moteo.fun
```

**Project-specific mitigation:**

The deployment script includes DNS polling before HTTPS verification.

### 5. TLS Certificate Not Issued by Cert-Manager

**Problem:**

The browser shows HTTPS errors or `kubectl get certificate -n production` does not show `READY=True`.

**Root cause:**

Common causes include incorrect DNS target, Ingress not reachable, wrong ClusterIssuer configuration, or ACME HTTP-01 challenge not being routed correctly.

**Troubleshooting commands:**

```bash
kubectl get clusterissuer
kubectl get certificate -n production
kubectl describe certificate moteo-tls-secret -n production
kubectl describe challenge -n production
kubectl get ingress -n production
```

**Solution:**

Verify DNS points to the NGINX Ingress load balancer, confirm the Ingress has the `cert-manager.io/cluster-issuer` annotation, and confirm port 80 is reachable for HTTP-01 validation.

### 6. Pods Fail Readiness or Rollout Timeout

**Problem:**

`kubectl rollout status` times out, or pods stay unavailable during deployment.

**Root cause:**

The application may not be responding on `/health`, environment variables may be wrong, MongoDB may be unavailable, or the image tag may not exist in Docker Hub.

**Troubleshooting commands:**

```bash
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
kubectl get events -n production --sort-by=.lastTimestamp
kubectl get deployment devops-final-app -n production -o yaml
```

**Solution:**

Fix the health endpoint or configuration, verify the image tag exists, and rely on pipeline rollback if production rollout fails.

### 7. Uploaded Images Disappear After Pod Restart

**Problem:**

Images uploaded through the application disappear or are inconsistent across replicas.

**Root cause:**

Kubernetes pod filesystem storage is ephemeral and not shared between replicas.

**Solution:**

Use AWS S3 for uploaded product images. The project streams uploads directly to S3 using `multer-s3`, stores the S3 URL in MongoDB, and serves images from S3.

## Design Decision Justifications

### Why Amazon EKS?

EKS provides managed Kubernetes control plane operations, integration with AWS load balancing and IAM, and production-grade orchestration capabilities. It allows the team to demonstrate Deployments, Services, Ingress, HPA, rolling updates, and self-healing without managing Kubernetes control plane nodes manually.

### Why Tier 5?

Tier 5 has the highest orchestration score ceiling and best matches enterprise DevOps practices. Kubernetes demonstrates scalability, self-healing, declarative deployment, namespace separation, and production-style traffic management.

### Why GitHub Actions as the primary pipeline?

GitHub Actions integrates directly with the GitHub repository, supports encrypted secrets, provides native branch and path triggers, supports manual production approvals through GitHub Environments, and is easier to operate reliably than a self-hosted deployment pipeline.

### Why keep Jenkins?

Jenkins demonstrates self-hosted CI/CD infrastructure as an extra-credit feature. It is deployed on a separate EC2 instance, exposed through a custom domain, secured with HTTPS, and used for supplementary CI validation.

### Why use two Availability Zones?

Two AZs improve availability compared with a single-zone deployment while controlling cost. This is appropriate for a student project. A stricter production system could use three AZs and one NAT Gateway per AZ.

### Why one NAT Gateway?

One NAT Gateway reduces AWS cost. The trade-off is lower resilience if the AZ containing the NAT Gateway fails. This limitation is documented and acceptable for the academic project scope.

### Why use NGINX Ingress instead of exposing the app Service as LoadBalancer?

Ingress provides one controlled external entry point with TLS termination and path/host routing. Keeping the application Service as `ClusterIP` avoids creating a second public AWS load balancer that could bypass HTTPS policy.

### Why use commit SHA Docker tags instead of `latest`?

Commit SHA tags make each image immutable and traceable to a specific source revision. This improves rollback, debugging, and reproducibility. The `latest` tag is ambiguous and can point to different images over time.

### Why staging and production namespaces?

Namespaces provide logical isolation. Staging validates the same image before production promotion, while production remains protected by a manual approval gate.

### Why MongoDB in Kubernetes instead of a managed database?

MongoDB in Kubernetes demonstrates PersistentVolumeClaim usage and keeps the project self-contained. For a real enterprise production system, Amazon DocumentDB or MongoDB Atlas would reduce operational burden and improve managed backup/availability features.

### Why S3 for uploaded files?

Pods are ephemeral and multiple replicas cannot safely share local filesystem uploads. S3 provides durable object storage that works consistently across all replicas and pod restarts.

### Why kube-prometheus-stack?

It bundles Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter with production-ready integration through the Prometheus Operator. This is faster and more reliable than manually wiring each component.

### Why Loki for logging?

Loki integrates naturally with Grafana and Kubernetes labels. It provides centralized logs without requiring a heavier ELK stack.

## Evaluator Questions and Suggested Answers

### What architecture tier did you choose, and how does the implementation prove it?

We chose Tier 5, Kubernetes-Based Architecture. The implementation runs on Amazon EKS and uses Kubernetes Deployments, Services, Ingress, namespaces, PersistentVolumeClaims, HPA, readiness probes, rolling updates, and self-healing through ReplicaSets.

### How does your CI pipeline meet the mandatory requirements?

The GitHub Actions CI job runs automatically on pushes to `main`. It uses npm caching, installs dependencies with `npm ci`, runs ESLint, runs Trivy security scanning, builds a Docker image, tags it with the commit SHA, and pushes it to Docker Hub.

### How does your CD pipeline deploy safely?

The pipeline deploys to staging automatically after CI passes. Production deployment requires manual approval. Kubernetes uses rolling updates with readiness probes, and the pipeline runs rollout status checks. If production rollout fails, it automatically performs `kubectl rollout undo`.

### How do you prove the deployed version matches the source code?

Docker images are tagged with the short Git commit SHA. The pipeline substitutes that same SHA into Kubernetes manifests. This links the running image back to the exact commit.

### How is HTTPS implemented?

For the production app, NGINX Ingress receives public traffic and Cert-Manager provisions a Let's Encrypt certificate using ACME HTTP-01. The certificate is stored as a Kubernetes Secret and referenced by the Ingress. Jenkins uses Nginx and Certbot on EC2.

### How do you demonstrate self-healing?

We delete one production pod with `kubectl delete pod`. The ReplicaSet detects that the desired replica count is not met and creates a replacement pod automatically. Grafana and `kubectl get pods -w` show the recovery.

### How do you demonstrate autoscaling?

We run a stress test against the production application and watch `kubectl get hpa -n production -w`. HPA scales pods from 2 up to a maximum of 5 when CPU or memory utilization exceeds the configured targets.

### What happens if a deployment fails?

The production job waits for rollout status. If the deployment does not become healthy within the timeout, the pipeline executes `kubectl rollout undo` and exits with a failure status so the team is notified.

### What monitoring do you have?

We use kube-prometheus-stack for Prometheus, Grafana, Alertmanager, kube-state-metrics, and node-exporter. We also added custom application metrics through `prom-client`, scraped by Prometheus through a ServiceMonitor. Loki and Promtail provide centralized logs.

### What custom metrics did you implement?

The application exposes request count, request duration, active requests, product CRUD operation count, and S3 upload count through the `/metrics` endpoint.

### What alerts did you configure?

We configured PodCrashLooping, HighCPUUsage, HighMemoryUsage, and DeploymentReplicasMismatch alerts using PrometheusRule resources.

### Why is the application Service not a LoadBalancer?

The application Service is `ClusterIP` because external access should go through NGINX Ingress only. This keeps TLS termination and routing centralized and avoids creating an extra public load balancer.

### What are the main limitations of the current design?

The main limitations are a single NAT Gateway, a single MongoDB pod, and Jenkins being supplementary rather than the primary deployment engine. These choices were made to balance cost, complexity, and academic scope.

### What would you improve in a real production deployment?

Use multi-AZ NAT Gateways, managed MongoDB such as MongoDB Atlas or Amazon DocumentDB, external secret management such as AWS Secrets Manager, private ECR instead of Docker Hub, GitOps with Argo CD or Flux, and stronger alert notification integrations such as Slack or email routing.

### How do you avoid committing secrets?

Secrets are stored in GitHub Actions encrypted secrets or generated locally by Terraform. Private keys, Terraform state, and credential files are excluded using `.gitignore`.

### Why is S3 needed if MongoDB already exists?

MongoDB stores structured product data and S3 stores binary image files. Storing images in S3 avoids pod filesystem data loss and avoids duplicating files across replicas.

### How does staging use MongoDB safely?

Staging connects to the production MongoDB service through Kubernetes cross-namespace DNS but uses a separate database name, `products_db_staging`, to isolate staging data from production data.

### How do you know monitoring reflects production and not local data?

Prometheus scrapes Kubernetes Services in the EKS cluster, and Grafana dashboards filter by the `production` namespace. The metrics come from live pods running in EKS.

### What extra-credit features are included?

The project includes self-hosted Jenkins with HTTPS, multi-environment deployment with a manual approval gate, rolling updates, automated rollback, Alertmanager alerts, centralized logging with Loki, and custom application-level Prometheus metrics.
