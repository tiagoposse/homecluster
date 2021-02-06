
resource "kubernetes_cluster_role" "cr_reader" {
  metadata {
    name = "dashboard-reader"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces", "services", "nodes", "events"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "crb_reader" {
  metadata {
    name = "dashboard-reader"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "dashboard-reader"
  }
  subject {
    kind      = "User"
    name      = "system:serviceaccount:tools:dashboard-sa"
    api_group = "rbac.authorization.k8s.io"
  }
}

resource "kubernetes_role" "r_reader" {
  metadata {
    name = "dashboard-reader"
    namespace = local.namespace
  }

  rule {
    api_groups     = [""]
    resources      = ["secrets"]
    verbs          = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding" "rb_reader" {
  metadata {
    name      = "dashboard-reader"
    namespace = local.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "dashboard-reader"
  }
  subject {
    kind      = "User"
    name      = "system:serviceaccount:tools:dashboard-sa"
    api_group = "rbac.authorization.k8s.io"
  }
}