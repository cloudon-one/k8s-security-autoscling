variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace for Karpenter"
  type        = string
  default     = "karpenter"
}

variable "keda_namespace" {
  description = "Namespace for KEDA"
  type        = string
  default     = "keda"
}

variable "karpenter_controller_role_name" {
  description = "Name of the IAM role for Karpenter controller (IRSA)"
  type        = string
  default     = "karpenter-controller"
}

variable "karpenter_service_account" {
  description = "Karpenter controller service account name"
  type        = string
  default     = "karpenter"
}

variable "karpenter_chart_version" {
  description = "Karpenter Helm chart version (e.g., 1.1.0)"
  type        = string
  default     = "1.1.0"
}

variable "keda_chart_version" {
  description = "KEDA Helm chart version"
  type        = string
  default     = "2.17.2"
}