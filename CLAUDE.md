# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Kubernetes security and auto-scaling infrastructure project for Amazon EKS that combines:
- **Security Layer**: Trivy, Kyverno, Falco, Kube-bench, Kubescape
- **Auto-scaling Layer**: KEDA (event-driven pod scaling) and Karpenter (node provisioning)

The repository is purely infrastructure-as-code with no application code - only Terraform configurations, Kubernetes manifests, and Helm values files.

## Architecture

The project follows a two-tier approach:
1. **Infrastructure Deployment**: Terraform manages IAM roles, Helm installations
2. **Manifest Application**: Kubernetes YAML files configure specific resources

### Directory Structure
- `autoscaling/terraform/` - Terraform modules for KEDA and Karpenter setup
- `autoscaling/manifests/` - Kubernetes manifests for scaling configurations
- `security/` - Security tool configurations and manifests
- Root level - Project documentation and license

## Common Commands

### Terraform Operations
```bash
cd autoscaling/terraform
terraform init
terraform plan -var aws_region=eu-central-1 -var cluster_name=<eks-cluster-name>
terraform apply -var aws_region=eu-central-1 -var cluster_name=<eks-cluster-name>
```

Required variables:
- `aws_region` - Target AWS region
- `cluster_name` - Existing EKS cluster name

### Kubernetes Manifest Deployment

**Security setup:**
```bash
cd security
kubectl apply -f rbac.yaml
kubectl apply -f kyverno.yaml
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco -n security -f falco-values.yaml
kubectl apply -f kube-bench.yaml
kubectl apply -f kubescape.yaml
```

**Auto-scaling setup (order matters):**
```bash
cd autoscaling/manifests
kubectl apply -f karpenter-ec2nodeclass.yaml
kubectl apply -f karpenter-nodepool.yaml
kubectl apply -f keda-scaledobject-sqs.yaml
```

### Monitoring and Verification

**Node and pod scaling:**
```bash
kubectl get nodes -l karpenter.sh/nodepool=workers-spot -w
kubectl get pods -l app=orders-consumer -w
kubectl get scaledobject -A
kubectl describe scaledobject orders-consumer
```

**Security validation:**
```bash
kubectl get events --field-selector reason=PolicyViolation
kubectl logs -n security -l app.kubernetes.io/name=falco -f
kubectl logs -n security -l app=kube-bench
kubectl get policyreport -A
```

**AWS SQS queue monitoring:**
```bash
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names ApproximateNumberOfMessages
```

## Key Configuration Notes

### Terraform Variables
Located in `autoscaling/terraform/variables.tf`:
- Default Karpenter chart version: 1.1.0
- Default KEDA chart version: 2.17.2
- Configurable namespaces (default: karpenter, keda)

### Karpenter Configuration
- Uses spot instances with 72-hour expiry
- Instance types: c5/c6i, m5/m6i families (generation > 5)
- Max capacity: 1000 vCPUs
- Taint: `spot:NoSchedule` for workload isolation

### KEDA Configuration
- Trigger: AWS SQS queue depth
- Scaling range: 0-200 replicas
- Threshold: 100 messages per replica
- Target deployment: `orders-consumer`

### Security Policies
- Kyverno blocks privileged containers and `:latest` tags
- Falco monitors runtime threats with Slack integration
- Compliance scans run on scheduled intervals

## Prerequisites

- AWS CLI v2 configured with appropriate permissions
- kubectl configured for target EKS cluster
- Terraform >= 1.0
- Helm v3
- EKS cluster with OIDC provider enabled

## Important Dependencies

1. **EKS cluster must exist** before running Terraform
2. **OIDC provider must be configured** for IAM roles for service accounts
3. **Subnets and security groups** must be tagged with `karpenter: "true"`
4. **Execute manifests in order**: EC2NodeClass → NodePool → ScaledObject

## Troubleshooting

**Karpenter issues:**
- Check IAM permissions: `kubectl logs -n karpenter -l app.kubernetes.io/name=karpenter`
- Verify subnet tags: `aws ec2 describe-subnets --filters "Name=tag:karpenter,Values=true"`

**KEDA issues:**
- Check SQS permissions: `kubectl logs -n keda -l app.kubernetes.io/name=keda-operator`
- Verify queue URL and region in ScaledObject

**Security policy blocks:**
- Review policy reports: `kubectl get policyreport -A`
- Check Kyverno logs: `kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno`