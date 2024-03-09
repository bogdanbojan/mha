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
          "port" = 8080
          "protocol" = "TCP"
          "targetPort" = 8080
        },
      ]
      "selector" = {
        "app" = "coin-check"
      }
      "type" = "LoadBalancer"
    }
  }
}
