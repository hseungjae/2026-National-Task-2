# OpenTelemetry Collector (DaemonSet: o11y-otel)
# filelog(/var/log/pods/*/*/*.log) -> k8sattributes -> Loki(OTLP HTTP)

resource "kubernetes_service_account" "otel" {
  metadata {
    name      = "o11y-otel"
    namespace = var.monitoring_namespace
  }
}

resource "kubernetes_cluster_role" "otel" {
  metadata {
    name = "o11y-otel"
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces", "nodes"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "otel" {
  metadata {
    name = "o11y-otel"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.otel.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.otel.metadata[0].name
    namespace = var.monitoring_namespace
  }
}

resource "kubernetes_config_map" "otel" {
  metadata {
    name      = "o11y-otel"
    namespace = var.monitoring_namespace
  }

  data = {
    "config.yaml" = yamlencode({
      receivers = {
        filelog = {
          include           = ["/var/log/pods/*/*/*.log"]
          start_at          = "end"
          include_file_path = true
          operators = [
            { type = "container" }
          ]
        }
      }
      processors = {
        k8sattributes = {
          auth_type   = "serviceAccount"
          passthrough = false
          pod_association = [
            { sources = [{ from = "resource_attribute", name = "k8s.pod.uid" }] },
            { sources = [{ from = "connection" }] }
          ]
          extract = {
            metadata = [
              "k8s.namespace.name",
              "k8s.pod.name",
              "k8s.container.name",
            ]
          }
        }
        batch = {}
      }
      exporters = {
        "otlphttp/loki" = {
          endpoint = "${var.loki_url}/otlp"
        }
      }
      service = {
        pipelines = {
          logs = {
            receivers  = ["filelog"]
            processors = ["k8sattributes", "batch"]
            exporters  = ["otlphttp/loki"]
          }
        }
      }
    })
  }
}

resource "kubernetes_daemonset" "otel" {
  metadata {
    name      = "o11y-otel"
    namespace = var.monitoring_namespace
    labels = {
      app = "o11y-otel"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "o11y-otel"
      }
    }

    template {
      metadata {
        labels = {
          app = "o11y-otel"
        }
        annotations = {
          # ConfigMap 변경 시 롤아웃 유발
          "checksum/config" = sha1(kubernetes_config_map.otel.data["config.yaml"])
        }
      }

      spec {
        service_account_name = kubernetes_service_account.otel.metadata[0].name

        security_context {
          run_as_user = 0
        }

        container {
          name  = "otel-collector"
          image = "otel/opentelemetry-collector-contrib:0.156.0"
          args  = ["--config=/conf/config.yaml"]

          volume_mount {
            name       = "config"
            mount_path = "/conf"
          }
          volume_mount {
            name       = "varlogpods"
            mount_path = "/var/log/pods"
            read_only  = true
          }
          volume_mount {
            name       = "varlibdockercontainers"
            mount_path = "/var/lib/docker/containers"
            read_only  = true
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              memory = "256Mi"
            }
          }
        }

        volume {
          name = "config"
          config_map {
            name = kubernetes_config_map.otel.metadata[0].name
          }
        }
        volume {
          name = "varlogpods"
          host_path {
            path = "/var/log/pods"
          }
        }
        volume {
          name = "varlibdockercontainers"
          host_path {
            path = "/var/lib/docker/containers"
          }
        }

        toleration {
          operator = "Exists"
        }
      }
    }
  }
}
