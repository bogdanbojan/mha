resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "mha-ingress"
    namespace = "default"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      http {
        path {
          backend {
            service {
              name = "coin-check"
              port {
                number = 8080
              }
            }
          }

          path = "/current"
        }

        path {
          backend {
            service {
              name = "coin-check"
              port {
                number = 8080
              }
            }
          }

          path = "/average"
        }
        
        path {
          backend {
            service {
              name = "ok"
              port {
                number = 8081
              }
            }
          }

          path = "/ok"
        }
      }
    }

  }
}
