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

resource "kubernetes_manifest" "service_ok" {
  manifest = {
    "apiVersion" = "v1"
    "kind" = "Service"
    "metadata" = {
      "name" = "ok"
      "namespace" = "default"
    }
    "spec" = {
      "ports" = [
        {
          "port" = 8081
          "protocol" = "TCP"
          "targetPort" = 8081
        },
      ]
      "selector" = {
        "app" = "ok"
      }
      "type" = "LoadBalancer"
    }
  }
}
