resource "helm_release" "vi-helm" {
  name  = "vi"
  chart = "./helm/helm-local/helm-vi"

  values = [templatefile("${path.module}/template.yaml", {
  })]
}
