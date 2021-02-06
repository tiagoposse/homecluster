
# resource "kubernetes_network_policy" "builds" {
#   metadata {
#     name      = "drone-build"
#     namespace = local.runner.namespace
#   }
        
#   spec {
#     pod_selector {
#       match_labels = {
#         "app.kubernetes.io/component" = local.runner.chart
#         "app.kubernetes.io/instance"  = local.runner.name
#       }
#     }

#     ingress {
#       ports {
#         port     = "drone"
#         protocol = "TCP"
#       }

#       from {
#         namespace_selector {
#           match_labels = {
#             name = local.drone.namespace
#           }
#         }

#         pod_selector {
#           match_labels = {
#             "app.kubernetes.io/component" = "server"
#             "app.kubernetes.io/instance" = local.drone.chart
#             "app.kubernetes.io/name" = local.drone.name
#           }
#         }
#       }
#     }

#     policy_types = ["Ingress"]
#   }
# }

# resource "kubernetes_network_policy" "monorepo" {
#   metadata {
#     name      = "monorepo"
#     namespace = local.monorepo.namespace
#   }
        
#   spec {
#     pod_selector {
#       match_labels = {
#         "app.kubernetes.io/component" = local.monorepo.chart
#         "app.kubernetes.io/instance"  = local.monorepo.name
#       }
#     }

#     ingress {
#       ports {
#         port     = "drone"
#         protocol = "TCP"
#       }

#       from {
#         namespace_selector {
#           match_labels = {
#             name = local.drone.namespace
#           }
#         }

#         pod_selector {
#           match_labels = {
#             "app.kubernetes.io/component" = "server"
#             "app.kubernetes.io/instance" = local.drone.chart
#             "app.kubernetes.io/name" = local.drone.name
#           }
#         }
#       }
#     }

#     policy_types = ["Ingress"]
#   }
# }

# resource "kubernetes_network_policy" "ingress" {
#   metadata {
#     name      = "default-deny-ingress"
#     namespace = local.monorepo.namespace
#   }
        
#   spec {
#     pod_selector {}
#     policy_types = ["Ingress"]
#   }
# }
