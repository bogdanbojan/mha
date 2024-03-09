resource "kubernetes_secret" "reg-aws" {
  metadata {
    name = "reg-aws"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.registry_server}" = {
          "username" = var.registry_username
          "password" = data.aws_secretsmanager_secret_version.registry_password.secret_string
          "email"    = var.registry_email
          "auth"     = base64encode("${var.registry_username}:${data.aws_secretsmanager_secret_version.registry_password.secret_string}")
        }
      }
    })
  }
}

