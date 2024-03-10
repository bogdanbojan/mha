resource "kubernetes_manifest" "networkpolicy_access_nginx" {
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind" = "NetworkPolicy"
    "metadata" = {
      "name" = "access-nginx"
      "namespace" = "default"
    }
    "spec" = {
      "egress" = [
        {
          "to" = [
            {
              "podSelector" = {
                "matchLabels" = {
                  "app.kubernetes.io/name" = "nginx-ingress-controller"
                }
              }
            },
          ]
        },
      ]
      "ingress" = [
        {
          "from" = [
            {
              "podSelector" = {
                "matchLabels" = {
                  "app.kubernetes.io/name" = "nginx-ingress-controller"
                }
              }
            },
          ]
        },
      ]
      "podSelector" = {}
    }
  }
}

