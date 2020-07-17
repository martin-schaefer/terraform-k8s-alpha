terraform {
  required_version = ">= 0.12"
}

provider "kubernetes-alpha" {
  config_path = "~/.kube/config" // path to kubeconfig
}

variable "app_namespace" {
  type = string
  default = "apps"
}

variable "version_k8s-be" {
  type = string
}

variable "version_k8s-bff" {
  type = string
}

variable "version_k8s-sba" {
  type = string
}

resource "null_resource" "istio" {
  provisioner "local-exec" {
    command = "istioctl install --set profile=demo"
  }
}

# The apps namespace
module "apps-namespace" {
  source = "./apps-namespace"
  app_namespace = var.app_namespace
}

# The apps
module "k8s-be" {
  source = "./spring-boot-app"
  app_name = "k8s-be"
  app_version = var.version_k8s-be
  app_namespace = var.app_namespace
  app_replicas = 2
  node_port = 30001
}

module "k8s-bff" {
  source = "./spring-boot-app"
  app_name = "k8s-bff"
  app_version = var.version_k8s-bff
  app_namespace = var.app_namespace
  app_replicas = 2
  node_port = 30002
}

module "k8s-sba" {
  source = "./spring-boot-app"
  app_name = "k8s-sba"
  app_version = var.version_k8s-sba
  app_namespace = var.app_namespace
  node_port = 30003
}
