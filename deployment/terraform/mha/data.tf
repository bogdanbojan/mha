data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = "mha-tf-state"
    key = "state/terraform.tfstate"
    region= "eu-west-3"
  }
}

data "aws_eks_cluster" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_secretsmanager_secret" "registry_secret" {
  name = "registry_password"
}

data "aws_secretsmanager_secret_version" "registry_password" {
  secret_id = data.aws_secretsmanager_secret.registry_secret.id
}

data "kubernetes_service" "ingress_nginx" {

  metadata {
    name      = "nginx-ingress-controller"
    namespace = "default"
  }
  depends_on = [
    helm_release.nginx-ingress-controller
  ]
}
