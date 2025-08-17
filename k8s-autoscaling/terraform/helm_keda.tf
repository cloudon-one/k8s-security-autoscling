resource "helm_release" "keda" {
  name       = "keda"
  repository = "https://kedacore.github.io/charts"
  chart      = "keda"
  version    = var.keda_chart_version
  namespace  = var.keda_namespace
  create_namespace = true

  # Typical production toggles can be added under values
  values = [yamlencode({
    # metricsServer: {}
  })]
}