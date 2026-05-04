# GUIDING LIGHT - System Deploy & Destroy Guide

> This file helps you bring the DevOps Final Project up and down.
> The system is now fully automated - just run deploy.ps1 or destroy.ps1.

---

## DEPLOY (Bring Up Everything)

### One Command - Full Automation:
```powershell
cd "c:\Users\cbzer\DevOps_Final"
powershell -ExecutionPolicy Bypass -File ".\deploy.ps1"
```

**What it does automatically (8 steps, ~30-40 min):**
1. `terraform apply` - Creates VPC, EKS cluster, Jenkins EC2, S3 bucket
2. Connects kubectl to EKS, waits for nodes to be Ready
3. Installs NGINX Ingress Controller via Helm, waits for ELB
4. Installs Cert-Manager via Helm
5. Installs Prometheus + Grafana + Loki via Helm
6. Creates namespaces (production, staging) + applies all K8s manifests:
   - MongoDB (PVC + Deployment + Service)
   - App (Deployment + Service + HPA)
   - Ingress SSL + Alerting Rules + ServiceMonitor
7. **PAUSES** - shows DNS records to set on Hostinger, waits for Enter
8. After DNS confirmed - SSH into Jenkins and runs Certbot for HTTPS

**You only need to do manually:**
1. Set DNS records when script pauses (see screen for exact values):
   - `CNAME www` -> ELB hostname (shown on screen)
   - `A jenkins` -> Jenkins IP (shown on screen)
2. Complete Jenkins setup wizard at https://jenkins.moteo.fun

---

## MANUAL STEPS (After deploy.ps1 finishes)

### Jenkins Setup (first time only):
1. Go to https://jenkins.moteo.fun
2. Get initial password:
   ```powershell
   cd "c:\Users\cbzer\DevOps_Final"
   ssh -i infrastructure\jenkins-key.pem ubuntu@<JENKINS_IP>
   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Install suggested plugins
4. Create admin user
5. Create Pipeline Job:
   - Dashboard -> New Item -> name: `devops-final` -> Pipeline -> OK
   - Pipeline -> Pipeline script from SCM -> Git
   - URL: `https://github.com/DinhQuocCuong28664/DevOps_Final_Project.git`
   - Branch: `*/main`
   - Save -> Build Now

### Grafana Access:
```powershell
kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80
```
Open: http://localhost:3000

Get password:
```powershell
kubectl --namespace monitoring get secrets monitoring-stack-grafana `
  -o jsonpath="{.data.admin-password}" | `
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```
Username: `admin`

---

## VERIFY (Check Everything is Running)

```powershell
# Nodes
kubectl get nodes

# All pods
kubectl get pods -n production
kubectl get pods -n staging
kubectl get pods -n ingress-nginx
kubectl get pods -n monitoring

# SSL Certificate (wait 2-3 min after DNS is set)
kubectl get certificate -n production
# READY must be True

# HPA
kubectl get hpa -n production

# Alerting rules
kubectl get prometheusrule -n monitoring
```

Access:
- App:     https://www.moteo.fun
- Jenkins: https://jenkins.moteo.fun
- Grafana: http://localhost:3000 (after port-forward)

---

## HPA DEMO (Stress Test)

Open 2 terminals:

**Terminal 1 - Stress test:**
```powershell
node stress-test.js 200 https://www.moteo.fun
```
Output every 5 seconds: `[Stats] Total: ... RPS: ... Avg latency: ... Errors: ...`

**Terminal 2 - Watch HPA scale:**
```powershell
kubectl get hpa -n production -w
# Watch pods scale from 2 up to 5
```

**Terminal 3 - Watch pods:**
```powershell
kubectl get pods -n production -w
```

---

## FAILURE SIMULATION DEMO (Self-Healing)

```powershell
# 1. Show current pods (2 running)
kubectl get pods -n production

# 2. Delete one pod
kubectl delete pod <pod-name> -n production

# 3. Watch it auto-recreate within 5 seconds
kubectl get pods -n production -w
```

Alertmanager fires `DeploymentReplicasMismatch` during the brief downtime.

---

## DESTROY (Tear Down Everything)

### One Command:
```powershell
powershell -ExecutionPolicy Bypass -File ".\destroy.ps1"
```

**What it does automatically:**
1. Helm uninstall (ingress-nginx, cert-manager, loki-stack, monitoring-stack)
2. Waits 90 seconds for AWS Load Balancer to be fully released (prevents DependencyViolation)
3. Deletes all K8s resources (ingress, app, mongodb, HPA)
4. Deletes namespaces (production, staging, ingress-nginx, cert-manager, monitoring)
5. `terraform destroy` - removes all AWS resources (~10-15 min)

**After destroy, manually:**
- Go to Hostinger DNS -> Remove CNAME `www` and A `jenkins` records

---

## TROUBLESHOOTING

### PVC stuck in Pending:
```powershell
kubectl get pvc -n production
kubectl describe pvc mongodb-pvc -n production
```
If StorageClass issue: check `kubectl get storageclass` - must have `gp2`.

### EBS CSI Driver CrashLoop:
```powershell
kubectl get pods -n kube-system | findstr ebs
```
IAM policy may be missing. Run:
```powershell
aws iam attach-role-policy `
  --role-name <node-group-role-name> `
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy
kubectl rollout restart deployment/ebs-csi-controller -n kube-system
```
Note: eks.tf already includes this - only needed if deploying to existing cluster.

### App shows "Source: in memory" (not connected to MongoDB):
```powershell
kubectl get pods -n production         # Check mongodb pod is Running
kubectl get pvc -n production          # Check PVC is Bound
kubectl rollout restart deployment/devops-final-deployment -n production
```

### Terraform destroy leaves orphaned subnet/SG:
```powershell
# Find and delete orphaned ENIs
aws ec2 describe-network-interfaces `
  --filters "Name=subnet-id,Values=<subnet-id>" `
  --query "NetworkInterfaces[*].NetworkInterfaceId" --output text

aws ec2 delete-network-interface --network-interface-id <eni-id>
aws ec2 delete-subnet --subnet-id <subnet-id>
aws ec2 delete-security-group --group-id <sg-id>
```

### Grafana password (PowerShell):
```powershell
kubectl --namespace monitoring get secrets monitoring-stack-grafana `
  -o jsonpath="{.data.admin-password}" | `
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

### Jenkins HTTPS (manual certbot):
```powershell
ssh -i infrastructure\jenkins-key.pem ubuntu@<JENKINS_IP>
sudo certbot --nginx -d jenkins.moteo.fun --non-interactive --agree-tos -m admin@moteo.fun
```

---

## VERIFY AWS CLEAN (No Leftover Charges)

```powershell
aws eks list-clusters --region ap-southeast-2
aws ec2 describe-instances --region ap-southeast-2 --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[InstanceId,InstanceType,Tags[?Key=='Name'].Value|[0]]" --output table
aws elbv2 describe-load-balancers --region ap-southeast-2 --query "LoadBalancers[*].LoadBalancerName" --output table
aws ec2 describe-nat-gateways --region ap-southeast-2 --filter "Name=state,Values=available" --query "NatGateways[*].NatGatewayId" --output table
```
All should return empty (except piston-server which belongs to another project).
