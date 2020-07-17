# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Module for Spring Boot app standard deployment
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

variable "app_name" {
  type = string
}

variable "app_version" {
  type = string
}

variable "app_namespace" {
  type = string
}

variable "app_replicas" {
  type = number
  default = 1
}

variable "node_port" {
  type = number
}

resource "kubernetes_manifest" "spring-boot-app-config-map" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "ConfigMap"
    "metadata" = {
      "name" = "${var.app_name}"
      "namespace" = "${var.app_namespace}"
    }
    "data" = {
        "application.yml" = "${file("./app-config/${var.app_name}.yml")}"
    }
  }
}

resource "kubernetes_manifest" "spring-boot-app-deployment" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "apps/v1"
    "kind"       = "Deployment"
    "metadata" = {
      "name" = "${var.app_name}"
      "namespace" = "${var.app_namespace}"
    }
    "spec" = {
        "replicas" = var.app_replicas
        "selector" = {
            "matchLabels" = {
                "app" = "${var.app_name}"
            }
        }
        "template" = {
            "metadata" = {
                "labels" = {
                "app" = "${var.app_name}"
                "app_version" = "${var.app_version}"
                "fluentd-log-format" = "spring-boot-json"
            }
            "annotations" = {
                "prometheus.io/scrape" = "true"
                "prometheus.io/path" = "/actuator/prometheus"
                "prometheus.io/port" = "8010"
            }
        }
        "spec" = {
            "automountServiceAccountToken" = true
            "containers" = [{
                "name"  = "${var.app_name}-container"
                "image" = "gcr.io/handy-zephyr-272321/${var.app_name}:${var.app_version}"
                "ports" = [ {
                    "name" = "service-port"
                    "containerPort" = 80
                    "protocol"      = "TCP"
                },
                {
                    "name" = "management-port"
                    "containerPort" = 8010
                    "protocol"      = "TCP"
                }, ]
                "readinessProbe" = {
                    "httpGet" = {
                        "path" = "/actuator/health"
                        "port" = 8010
                    }
                    "timeoutSeconds" = 5
                    "periodSeconds" = 30
                    "successThreshold" = 1
                    "failureThreshold" = 1
                }
            },]
        }
    }
  }
}
}

resource "kubernetes_manifest" "spring-boot-app-service" {
  provider = kubernetes-alpha

  manifest = {
    "apiVersion" = "v1"
    "kind"       = "Service"
    "metadata" = {
      "name" = "${var.app_name}"
      "namespace" = "${var.app_namespace}"
        "labels" = {
          "sba-monitored" = "true"
        }
    }
    "spec" = {
        "selector" = {
            "app" = "${var.app_name}"
        }
        "ports" = [
        {
            "name" = "service"
            "port" = 80
            "nodePort" = "${var.node_port}"
            "protocol"      = "TCP"
        },
        {
            "name" = "management"
            "port" = 8010
            "protocol"      = "TCP"
        },
        ]
        "type" = "NodePort"
    }
  }
}
