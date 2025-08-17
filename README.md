# Kubernetes Security & Auto-scaling on EKS

Complete production-ready setup for secure, auto-scaling Kubernetes workloads on Amazon EKS with comprehensive security controls and event-driven scaling.

## 🏗️ Architecture Overview

```mermaid
graph TB
    subgraph "CI/CD Pipeline"
        A[Developer] --> B[Git Push]
        B --> C[Trivy Scan]
        C --> D[Build & Deploy]
    end
    
    subgraph "EKS Cluster"
        E[Kyverno] --> F[Pod Admission]
        G[KEDA] --> H[Workload Scaling]
        I[Karpenter] --> J[Node Provisioning]
        K[Falco] --> L[Runtime Security]
    end
    
    subgraph "Monitoring"
        M[Kube-bench] --> N[CIS Compliance]
        O[Kubescape] --> P[Security Posture]
        L --> Q[Slack Alerts]
    end
    
    D --> F
    H --> J
```

## 📋 Components

### Security Layer
- **Trivy**: Container image and IaC vulnerability scanning
- **Kyverno**: Policy-as-code admission controller
- **Falco**: Runtime threat detection with Slack integration
- **Kube-bench**: CIS Kubernetes benchmark compliance
- **Kubescape**: NIST/MITRE security posture assessment

### Auto-scaling Layer
- **KEDA**: Event-driven horizontal pod autoscaling (SQS-based)
- **Karpenter**: Just-in-time node provisioning with spot instances

## 🚀 Quick Start

### Prerequisites

```bash
# Required tools
aws --version        # AWS CLI v2
kubectl version      # Kubernetes CLI
terraform --version  # Terraform >= 1.0
helm version         # Helm v3

# EKS cluster with OIDC provider
aws eks describe-cluster --name <cluster-name> --query cluster.identity.oidc.issuer
```

### 1. Deploy Security Infrastructure

```bash
cd security
kubectl apply -f rbac.yaml
kubectl apply -f kyverno.yaml

# Install Falco with Slack integration
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n security -f falco-values.yaml

# Schedule compliance scans
kubectl apply -f kube-bench.yaml
kubectl apply -f kubescape.yaml
```

### 2. Deploy Auto-scaling Infrastructure

```bash
cd ../autoscaling/terraform

# Configure variables
export TF_VAR_aws_region="eu-central-1"
export TF_VAR_cluster_name="my-eks-cluster"

# Deploy
terraform init
terraform apply
```

### 3. Apply Scaling Manifests

```bash
cd ../manifests

# Apply in order (dependencies matter)
kubectl apply -f karpenter-ec2nodeclass.yaml
kubectl apply -f karpenter-nodepool.yaml
kubectl apply -f keda-scaledobject-sqs.yaml
```

## 🔧 Configuration Details

### Karpenter Node Provisioning

**EC2NodeClass** (`workers-spot`):
- **AMI**: Amazon Linux 2
- **Instance types**: c5/c6i, m5/m6i (generation > 5)
- **Capacity**: Spot instances with 72h expiry
- **Networking**: Auto-discovery via `karpenter: "true"` tags

**NodePool** specifications:
```yaml
limits:
  cpu: 1000                    # Max 1000 vCPUs
taints:
  - key: spot
    effect: NoSchedule          # Isolate spot workloads
disruption:
  consolidationPolicy: WhenUnderutilized
  expireAfter: 72h             # Force refresh every 3 days
```

### KEDA Event-driven Scaling

**ScaledObject** (`orders-consumer`):
- **Trigger**: AWS SQS queue depth
- **Scaling range**: 0-200 replicas
- **Threshold**: 100 messages per replica
- **Cooldown**: 60 seconds between scale events

```yaml
triggers:
  - type: aws-sqs-queue
    metadata:
      queueURL: https://sqs.eu-central-1.amazonaws.com/123456789012/orders
      queueLength: "100"
```

### Security Policies

**Kyverno admission rules**:
- ❌ Privileged containers blocked
- ✅ Non-root execution required
- ❌ `:latest` image tags disallowed
- ✅ Resource requests/limits mandatory

**Falco runtime detection**:
- Suspicious syscalls → Slack alerts
- Container escapes → Immediate notification
- Privilege escalation → Security team alert

## 📊 Monitoring & Verification

### Real-time Monitoring

```bash
# Watch node auto-provisioning
kubectl get nodes -l karpenter.sh/nodepool=workers-spot -w

# Monitor workload scaling
kubectl get pods -l app=orders-consumer -w

# Check SQS queue depth
aws sqs get-queue-attributes \
  --queue-url https://sqs.eu-central-1.amazonaws.com/123456789012/orders \
  --attribute-names ApproximateNumberOfMessages
```

### Security Validation

```bash
# Check policy violations
kubectl get events --field-selector reason=PolicyViolation

# View Falco alerts
kubectl logs -n security -l app.kubernetes.io/name=falco -f

# Compliance scan results
kubectl logs -n security -l app=kube-bench
kubectl logs -n security -l app=kubescape
```

### Scaling Metrics

```bash
# KEDA scaling status
kubectl get scaledobject -A
kubectl describe scaledobject orders-consumer

# Karpenter provisioning
kubectl get nodepool -n karpenter
kubectl describe nodepool workers-spot
```

## 🔐 Security Best Practices

### CI/CD Integration

Add to `.github/workflows/security.yml`:
```yaml
- name: Trivy vulnerability scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: config
    severity: CRITICAL,HIGH
```

### Runtime Security

**Falco rules** detect:
- Shell spawned in container
- Sensitive file access
- Network connections from containers
- Privilege escalation attempts

### Compliance Automation

**Scheduled scans**:
- Kube-bench: Daily CIS compliance check
- Kubescape: NIST/MITRE posture assessment
- Results exported to JSON for SIEM integration

## 🛠️ Troubleshooting

### Common Issues

**Karpenter nodes not provisioning**:
```bash
# Check IAM permissions
kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter

# Verify subnet/SG tags
aws ec2 describe-subnets --filters "Name=tag:karpenter,Values=true"
```

**KEDA not scaling**:
```bash
# Check SQS permissions
kubectl logs -n keda -l app.kubernetes.io/name=keda-operator

# Verify queue URL and region
kubectl describe scaledobject orders-consumer
```

**Security policy blocks**:
```bash
# Check Kyverno policy reports
kubectl get policyreport -A

# Review admission controller logs
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
```

## 📚 Additional Resources

- [Karpenter Best Practices](https://karpenter.sh/docs/concepts/)
- [KEDA Scalers Documentation](https://keda.sh/docs/scalers/)
- [Falco Rules Reference](https://falco.org/docs/rules/)
- [Kyverno Policy Library](https://kyverno.io/policies/)

## 🏷️ Tags & Labels

All resources use consistent labeling:
```yaml
labels:
  app.kubernetes.io/name: <component>
  app.kubernetes.io/version: <version>
  environment: production
  team: platform
```

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.