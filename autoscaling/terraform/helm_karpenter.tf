# Install CRDs first
resource "helm_release" "karpenter_crds" {
  name             = "karpenter-crd"
  repository       = "oci://public.ecr.aws/karpenter/karpenter-crd"
  chart            = "karpenter-crd"
  version          = var.karpenter_chart_version
  namespace        = var.karpenter_namespace
  create_namespace = true
}

# Install controller
resource "helm_release" "karpenter" {
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_chart_version
  namespace  = var.karpenter_namespace
  depends_on = [helm_release.karpenter_crds]

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = var.karpenter_service_account
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.karpenter_controller.arn
      }
    }
    settings = {
      clusterName       = var.cluster_name
      interruptionQueue = "" # optional: if using interruption handling via SQS
    }
    controller = {
      resources = {
        requests = { cpu = "200m", memory = "256Mi" }
        limits   = { cpu = "1", memory = "512Mi" }
      }
    }
  })]
}