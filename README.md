# KEDA + Karpenter on EKS

## Set variables and apply Terraform

```
cd terraform
terraform init
terraform apply -var aws_region=eu-central-1 -var cluster_name=<eks-name>
```

## Apply manifests in order

```
cd ../manifests
kubectl apply -f karpenter-ec2nodeclass.yaml
kubectl apply -f karpenter-nodepool.yaml
kubectl apply -f keda-scaledobject-sqs.yaml
```

## Verify

```
kubectl get pods -n karpenter
kubectl get deployment keda-operator -n keda
kubectl get nodepool -n karpenter
kubectl get scaledobject -A
```

### KEDA installs from the official Helm repo￼

- Karpenter installs via OCI charts. Install CRDs first, then the controller.  ￼
- Use EC2NodeClass and NodePool APIs as shown.  ￼
- The ScaledObject CRD and metadata fields follow current spec