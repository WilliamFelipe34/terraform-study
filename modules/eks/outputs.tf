locals {
  Kubeconfig = jsonencode({
    //copiar e colar configs do kubernet da doc
  })
}

resource "local_file" "kubeconig" {
  filename = "kubeconfig"
  content = local.Kubeconfig
}