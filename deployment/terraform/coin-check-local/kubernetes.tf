terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}


variable "host" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "registry_server" {
  type = string
}

variable "registry_username" {
  type = string
}

variable "registry_password" {
  type = string
}

variable "registry_email" {
  type = string
}

provider "kubernetes" {
  host = var.host

  client_certificate     = base64decode(var.client_certificate)
  client_key             = base64decode(var.client_key)
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
}

resource "kubernetes_manifest" "deployment_coin_check" {
  manifest = {
    "apiVersion" = "apps/v1"
    "kind" = "Deployment"
    "metadata" = {
      "name" = "coin-check"
      "namespace" = "default"
    }
    "spec" = {
      "replicas" = 1
      "selector" = {
        "matchLabels" = {
          "app" = "coin-check"
        }
      }
      "template" = {
        "metadata" = {
          "labels" = {
            "app" = "coin-check"
          }
        }
        "spec" = {
          "containers" = [
            {
              "image" = "198760508209.dkr.ecr.eu-west-3.amazonaws.com/coin-check:latest"
              "imagePullPolicy" = "Always"
              "name" = "coin-check"
              "ports" = [
                {
                  "containerPort" = 8080
                },
              ]
            },
          ]
          "imagePullSecrets" = [
            {
              "name" = "reg-aws"
            },
          ]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "service_coin_check" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "coin-check"
      "namespace" = "default"
    }
    "spec" = {
      "ports" = [
        {
          "nodePort" = 30000
          "port" = 8080
          "protocol" = "TCP"
          "targetPort" = 8080
        },
      ]
      "selector" = {
        "app" = "coin-check"
      }
      "type" = "NodePort"
    }
  }
}

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
          "password" = var.registry_password
          "email"    = var.registry_email
          "auth"     = base64encode("${var.registry_username}:${var.registry_password}")
        }
      }
    })
  }
}
