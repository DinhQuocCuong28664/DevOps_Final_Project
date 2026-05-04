# Diagram Report — Mermaid Diagrams for Technical_Report.md

This file contains all diagram-based figures from the Technical Report as Mermaid code.
Render each diagram using [mermaid.live](https://mermaid.live) or a VS Code Mermaid extension, then save as PNG to `images/`.

---

## Figure 1: High-Level System Architecture Diagram

```mermaid
graph TD
    subgraph "Development & CI/CD"
        A[GitHub Repository] --> B[GitHub Actions CI/CD]
        A --> C[Jenkins on EC2]
    end

    subgraph "Container Registry"
        D[Docker Hub Registry]
    end

    subgraph "Cloud Infrastructure - AWS ap-southeast-2"
        subgraph "VPC 10.0.0.0/16"
            subgraph "Public Subnets"
                Pub1["Public Subnet A<br/>10.0.101.0/24"]
                Pub2["Public Subnet B<br/>10.0.102.0/24"]
            end
            subgraph "Private Subnets"
                Priv1["Private Subnet A<br/>10.0.1.0/24"]
                Priv2["Private Subnet B<br/>10.0.2.0/24"]
            end
            IGW[Internet Gateway]
            NAT[NAT Gateway]
            subgraph "EKS Cluster"
                Ingress[NGINX Ingress Controller]
                Svc[Service ClusterIP]
                Pod1[Pod - App Replica 1]
                Pod2[Pod - App Replica 2]
                HPA[Horizontal Pod Autoscaler<br/>2 → 5 replicas]
                Mongo[(MongoDB<br/>PersistentVolume)]
            end
            S3[(S3 Bucket<br/>Image Uploads)]
        end
    end

    subgraph "Monitoring & Observability"
        Prom[Prometheus]
        Graf[Grafana Dashboards]
        Loki[Loki + Promtail<br/>Centralised Logging]
        Alert[Alertmanager]
    end

    B -->|docker push| D
    C -->|docker push| D
    D -->|kubectl apply| EKS
    EKS --> S3
    EKS --> Prom
    Prom --> Graf
    Loki --> Graf
    Prom --> Alert

    User((User)) -->|HTTPS www.moteo.fun| IGW
    IGW --> Ingress
    Ingress --> Svc
    Svc --> Pod1
    Svc --> Pod2
    Pod1 --> Mongo
    Pod2 --> Mongo
    Pod1 --> S3
    Pod2 --> S3
    HPA -.->|scale| Pod1
    HPA -.->|scale| Pod2
```

---

## Figure 3: VPC Network Topology Diagram

```mermaid
graph TD
    Internet((Internet))

    subgraph "AWS Cloud - ap-southeast-2"
        subgraph "VPC 10.0.0.0/16"
            IGW[Internet Gateway]

            subgraph "Availability Zone A - ap-southeast-2a"
                PubSubA["Public Subnet A<br/>10.0.101.0/24<br/>kubernetes.io/role/elb = 1"]
                PrivSubA["Private Subnet A<br/>10.0.1.0/24<br/>kubernetes.io/role/internal-elb = 1"]
            end

            subgraph "Availability Zone B - ap-southeast-2b"
                PubSubB["Public Subnet B<br/>10.0.102.0/24<br/>kubernetes.io/role/elb = 1"]
                PrivSubB["Private Subnet B<br/>10.0.2.0/24<br/>kubernetes.io/role/internal-elb = 1"]
            end

            NAT[NAT Gateway<br/>Single AZ - Cost Optimised]

            subgraph "Public Resources"
                Jenkins[Jenkins EC2<br/>t3.small]
                ELB[AWS ELB<br/>NGINX Ingress]
            end

            subgraph "Private Resources"
                Worker1[EKS Worker Node 1<br/>t3.medium]
                Worker2[EKS Worker Node 2<br/>t3.medium]
            end
        end
    end

    Internet --> IGW
    IGW --> PubSubA
    IGW --> PubSubB
    PubSubA --> Jenkins
    PubSubB --> ELB
    PubSubA --> NAT
    NAT --> PrivSubA
    NAT --> PrivSubB
    PrivSubA --> Worker1
    PrivSubB --> Worker2
```

---

## Figure 22: Ingress Traffic Flow Diagram

```mermaid
sequenceDiagram
    participant User as User Browser
    participant DNS as DNS<br/>www.moteo.fun
    participant ELB as AWS ELB<br/>(LoadBalancer)
    participant Ingress as NGINX Ingress Controller<br/>(ingress-nginx namespace)
    participant Cert as Cert-Manager<br/>Let's Encrypt
    participant Svc as Service<br/>(ClusterIP :80)
    participant Pod as Pod<br/>(App :3000)

    Note over User,DNS: Step 1: DNS Resolution
    User->>DNS: HTTPS GET www.moteo.fun
    DNS->>User: Resolves to AWS ELB DNS name

    Note over User,ELB: Step 2: TLS Termination
    User->>ELB: HTTPS Request
    ELB->>Ingress: Forward to NGINX Ingress

    Note over Ingress,Cert: Step 3: Certificate Check
    Ingress->>Cert: Verify TLS certificate
    Cert-->>Ingress: Valid Let's Encrypt cert<br/>(auto-renewed)

    Note over Ingress,Svc: Step 4: Routing
    Ingress->>Ingress: Terminate TLS
    Ingress->>Svc: Route to backend service<br/>(production namespace)

    Note over Svc,Pod: Step 5: Load Balancing
    Svc->>Pod: Forward to healthy pod<br/>(Round Robin)

    Note over Pod: Step 6: Application Processing
    Pod-->>User: HTTP 200 Response
```

---

## Figure 1 Alternative: Simplified Architecture (Flowchart Style)

```mermaid
flowchart LR
    subgraph Dev["Development & CI/CD"]
        GH[GitHub Repo] --> GA[GitHub Actions]
        GH --> J[Jenkins]
    end

    subgraph Reg["Container Registry"]
        DH[Docker Hub]
    end

    subgraph AWS["AWS Cloud"]
        subgraph VPC["VPC"]
            EKS[EKS Cluster]
            S3[S3 Bucket]
        end
    end

    subgraph Mon["Monitoring"]
        P[Prometheus]
        G[Grafana]
        L[Loki]
        A[Alertmanager]
    end

    GA -->|push image| DH
    J -->|push image| DH
    DH -->|deploy| EKS
    EKS -->|store files| S3
    EKS -->|scrape metrics| P
    P -->|visualise| G
    L -->|logs| G
    P -->|alerts| A
```

---

## Figure 3 Alternative: VPC with Route Tables

```mermaid
graph TB
    Internet((Internet))

    subgraph VPC["VPC 10.0.0.0/16"]
        IGW[Internet Gateway]

        subgraph RT_Public["Public Route Table"]
            PR1["Destination: 0.0.0.0/0 → IGW"]
        end

        subgraph RT_Private["Private Route Table"]
            PR2["Destination: 0.0.0.0/0 → NAT Gateway"]
        end

        subgraph AZ_A["Availability Zone A"]
            PubA["Public Subnet A<br/>10.0.101.0/24"]
            PrivA["Private Subnet A<br/>10.0.1.0/24"]
        end

        subgraph AZ_B["Availability Zone B"]
            PubB["Public Subnet B<br/>10.0.102.0/24"]
            PrivB["Private Subnet B<br/>10.0.2.0/24"]
        end

        NAT[NAT Gateway<br/>Elastic IP]
    end

    Internet --> IGW
    IGW --> RT_Public
    RT_Public --> PubA
    RT_Public --> PubB
    PubA --> NAT
    NAT --> RT_Private
    RT_Private --> PrivA
    RT_Private --> PrivB
```

---

## Figure 22 Alternative: Ingress with Detailed Components

```mermaid
flowchart TD
    User((User)) -->|"HTTPS<br/>www.moteo.fun"| ELB[AWS ELB<br/>Port 443]
    ELB -->|"TCP :443"| IC[NGINX Ingress Controller<br/>ingress-nginx namespace]

    subgraph Cert-Manager
        CA[Let's Encrypt<br/>ACME Server]
        CI[ClusterIssuer<br/>HTTP-01 Challenge]
        CS[Certificate Secret<br/>moteo-tls-secret]
    end

    subgraph Production["production namespace"]
        Ing[Ingress Resource<br/>host: www.moteo.fun]
        Svc[Service<br/>ClusterIP :80]
        D[Deployment<br/>RollingUpdate]
        HPA[HPA<br/>2 → 5 pods]
        Pod1[Pod 1<br/>App :3000]
        Pod2[Pod 2<br/>App :3000]
        PodN[Pod N<br/>App :3000]
    end

    IC -->|TLS termination| Ing
    Ing -->|cert-manager.io/cluster-issuer| CI
    CI -->|request cert| CA
    CA -->|issue cert| CS
    CS -->|TLS secret| Ing
    Ing -->|route /| Svc
    Svc -->|load balance| D
    D --> Pod1
    D --> Pod2
    D --> PodN
    HPA -.->|scale| D
```

---

## Usage Instructions

1. **Copy** any Mermaid code block above
2. Go to [mermaid.live](https://mermaid.live)
3. **Paste** into the editor
4. **Export** as PNG (or SVG)
5. **Save** to `images/` directory with naming:
   - `images/figure01-architecture-diagram.png`
   - `images/figure03-vpc-topology.png`
   - `images/figure22-ingress-flow.png`

### Alternative: VS Code Extension
1. Install **Markdown Preview Mermaid Support** extension
2. Open this file in VS Code
3. Right-click → **Open Preview**
4. Right-click on diagram → **Copy as PNG**
