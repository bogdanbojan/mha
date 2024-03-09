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

