resource "helm_release" "grafana" {
  name       = "o11y-grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = var.monitoring_namespace

  values = [yamlencode({
    fullnameOverride = "o11y-grafana"

    adminUser     = var.admin_user
    adminPassword = var.admin_password

    persistence = {
      enabled = true
      size    = "5Gi"
    }

    service = {
      type = "ClusterIP"
      port = 80
    }

    # Loki를 Datasource로 등록 (uid=loki 고정 -> 대시보드가 참조)
    datasources = {
      "datasources.yaml" = {
        apiVersion = 1
        datasources = [{
          name      = "Loki"
          type      = "loki"
          uid       = "loki"
          access    = "proxy"
          url       = var.loki_url
          isDefault = true
          editable  = true
        }]
      }
    }

    # 'Log Overview' 대시보드 프로비저닝
    dashboardProviders = {
      "dashboardproviders.yaml" = {
        apiVersion = 1
        providers = [{
          name            = "default"
          orgId           = 1
          folder          = ""
          type            = "file"
          disableDeletion = false
          editable        = true
          options = {
            path = "/var/lib/grafana/dashboards/default"
          }
        }]
      }
    }

    dashboards = {
      default = {
        log-overview = {
          json = file("${path.module}/dashboard.json")
        }
      }
    }
  })]
}
