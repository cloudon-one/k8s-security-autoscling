
# K8S Security Setup

## Diagram

```mermaid
Dev → CI
  └─ Trivy (IaC+image scan) ──> pass/fail gate
Deploy → Cluster API
  └─ Kyverno (validate/mutate/verify) ──> admit or deny
Runtime
  └─ Falco (syscall rules) ──> events → Slack/SIEM
Audit (scheduled)
  ├─ Kube-bench (CIS)
  └─ Kubescape (posture/RBAC)
```

