# Discover OIDC provider for IRSA
# If your cluster was created with eksctl or EKS module, the provider exists
# and aws_iam_openid_connect_provider data source can be used instead.

data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.cluster_name
}

data "aws_iam_openid_connect_provider" "oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# IAM role for Karpenter controller (IRSA)
resource "aws_iam_role" "karpenter_controller" {
  name               = var.karpenter_controller_role_name
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume.json
  tags               = local.karpenter_tags
}

data "aws_iam_policy_document" "karpenter_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.oidc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values = [
        "system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account}"
      ]
    }
  }
}

# Minimal recommended controller policy per Karpenter docs.
# This aggregates EC2, pricing, SSM, EKS Describe, and IAM PassRole to node role.
# Review and restrict as needed.
resource "aws_iam_policy" "karpenter_controller" {
  name   = "karpenter-controller-policy"
  policy = data.aws_iam_policy_document.karpenter_controller.json
}

data "aws_iam_policy_document" "karpenter_controller" {
  # EC2 fleet and discovery
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateLaunchTemplate",
      "ec2:CreateFleet",
      "ec2:DeleteLaunchTemplate",
      "ec2:Describe*",
      "ec2:GetInstanceTypesFromInstanceRequirements",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]
  }

  # Pricing API for spot/on-demand decisions
  statement {
    effect    = "Allow"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

  # SSM to discover AMIs (if using SSM parameter lookups)
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["*"]
  }

  # EKS Describe for cluster info
  statement {
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [data.aws_eks_cluster.this.arn]
  }

  # PassRole to node instance profile role; replace with your node role ARN if needed
  # Broad by default; tighten to specific role ARNs when known
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "ec2.amazonaws.com.cn"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}