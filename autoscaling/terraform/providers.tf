provider "aws" {
  region = var.aws_region
}
provider "kubernetes" {}
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}