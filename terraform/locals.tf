locals {
  karpenter_tags = {
    Project = var.cluster_name
  }
}