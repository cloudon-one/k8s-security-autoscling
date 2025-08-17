# KEDA + Karpenter on EKS

This project demonstrates auto-scaling on Amazon EKS using KEDA (Kubernetes Event-driven Autoscaling) for workload scaling and Karpenter for node provisioning.

## Architecture

- **KEDA**: Scales workloads based on SQS queue metrics
- **Karpenter**: Provisions EC2 spot instances automatically
- **EKS**: Managed Kubernetes cluster on AWS

## Prerequisites

- AWS CLI configured
- kubectl installed
- Terraform >= 1.0
- EKS cluster with OIDC provider

## Setup

### 1. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform apply -var aws_region=eu-central-1 -var cluster_name=<eks-name>
```

This creates:

- IAM roles for Karpenter controller and nodes
- Security groups and subnets tagged for Karpenter
- KEDA and Karpenter installations

### 2. Apply Kubernetes Manifests

```bash
cd ../manifests
kubectl apply -f karpenter-ec2nodeclass.yaml
kubectl apply -f karpenter-nodepool.yaml
kubectl apply -f keda-scaledobject-sqs.yaml
```

**Execution order matters**: EC2NodeClass → NodePool → ScaledObject

### 3. Verification

```bash
# Check Karpenter pods
kubectl get pods -n karpenter

# Verify KEDA operator
kubectl get deployment keda-operator -n keda

# Check node provisioning
kubectl get nodepool -n karpenter

# Monitor scaling objects
kubectl get scaledobject -A
```

## Configuration Details

### Karpenter NodePool

- **Instance types**: c5, c6i, m5, m6i (generation > 5)
- **Capacity type**: Spot instances with taint
- **Limits**: Max 1000 vCPUs
- **Disruption**: 72h expiry, consolidation enabled

### KEDA ScaledObject

- **Trigger**: AWS SQS queue length
- **Scaling**: 0-200 replicas based on queue depth
- **Threshold**: 100 messages per replica

## Monitoring

```bash
# Watch node scaling
kubectl get nodes -w

# Monitor workload scaling
kubectl get pods -w

# Check SQS metrics
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names ApproximateNumberOfMessages
```

## Notes

- Karpenter uses OCI Helm charts with separate CRD installation
- EC2NodeClass and NodePool follow v1 API specifications
- ScaledObject uses KEDA v1alpha1 API
- Spot instances include NoSchedule taint for workload isolation