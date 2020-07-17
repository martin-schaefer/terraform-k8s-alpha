# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Module for a namespace containing apps
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "app_namespace" {
  type = string
}

# The application namespace
resource "kubernetes_manifest" "apps-namespace" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Namespace"
    "metadata" = {
      "name" = "${var.app_namespace}"
      "labels" = {
        "istio-injection" = "enabled"
      }
    }
  }
}

# A reader role for the application namespace
resource "kubernetes_manifest" "namespace-reader-role" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "Role"
      "metadata" = {
        "name" = "namespace-reader"
        "namespace" = "${var.app_namespace}"
      }
      "rules" = [ {
        "apiGroups" = ["", "extensions", "apps", ]
        "resources" = ["namespaces", "configmaps", "pods", "services", "endpoints", "secrets", ]
        "verbs" = ["get", "list", "watch", ]
      }, ]
  }
}

# The default account in the application namespace has the reader role
resource "kubernetes_manifest" "namespace-reader-binding" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "rbac.authorization.k8s.io/v1"
    "kind"       = "RoleBinding"
    "metadata" = {
      "name" = "namespace-reader-binding"
      "namespace" = "${var.app_namespace}"
    }
    "roleRef" = {
      "kind"      = "Role"
      "name"      = "namespace-reader"
      "apiGroup" = "rbac.authorization.k8s.io"
    }
    "subjects" = [ {
      "kind"      = "ServiceAccount"
      "name"      = "default"
      "namespace" = "${var.app_namespace}"
      "apiGroup" = ""
    }, ]
  }
}
