resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# Loki (Single Binary 모드, PV 저장, OTLP ingestion 활성)
resource "helm_release" "loki" {
  name       = var.loki_release_name
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    loki = {
      auth_enabled = false
      commonConfig = {
        replication_factor = 1
      }
      storage = {
        type = "filesystem"
      }
      schemaConfig = {
        configs = [{
          from         = "2024-04-01"
          store        = "tsdb"
          object_store = "filesystem"
          schema       = "v13"
          index = {
            prefix = "index_"
            period = "24h"
          }
        }]
      }
      # OTLP 수신에 필수 (structured metadata 허용)
      limits_config = {
        allow_structured_metadata = true
        retention_period          = "168h"
      }
    }

    deploymentMode = "SingleBinary"

    singleBinary = {
      replicas = 1
      persistence = {
        enabled = true
        size    = "10Gi"
      }
    }

    # scalable 컴포넌트 비활성화 (single binary만 사용)
    read    = { replicas = 0 }
    write   = { replicas = 0 }
    backend = { replicas = 0 }

    # 불필요한 부가 컴포넌트 비활성화
    gateway      = { enabled = false }
    minio        = { enabled = false }
    chunksCache  = { enabled = false }
    resultsCache = { enabled = false }
    lokiCanary   = { enabled = false }
    test         = { enabled = false }
  })]
}
