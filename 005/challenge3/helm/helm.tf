resource "helm_release" "loki" {
  name             = "loki"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "loki"
  namespace        = "wsc-logging"
  create_namespace = true
  timeout          = 600

  values = [<<-YAML
    deploymentMode: SingleBinary

    loki:
      auth_enabled: false
      commonConfig:
        replication_factor: 1
      storage:
        type: filesystem
      schemaConfig:
        configs:
          - from: "2024-01-01"
            store: tsdb
            object_store: filesystem
            schema: v13
            index:
              prefix: loki_index_
              period: 24h

    singleBinary:
      replicas: 1
      persistence:
        enabled: true
        size: 10Gi

    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      port: 3100

    write:
      replicas: 0
    read:
      replicas: 0
    backend:
      replicas: 0

    gateway:
      enabled: false

    chunksCache:
      enabled: false

    resultsCache:
      enabled: false
  YAML
  ]

  depends_on = [var.node_group_name, var.gp2_default_annotation]
}

resource "kubernetes_config_map" "grafana_dashboard" {
  metadata {
    name      = "grafana-dashboard-cm"
    namespace = "wsc-logging"
  }

  data = {
    "grafana-dashboard.json" = jsonencode({
      "__inputs" = [
        { name = "DS_LOKI", label = "Loki", description = "", type = "datasource", pluginId = "loki", pluginName = "Loki" }
      ]
      "__elements" = {}
      "__requires" = [
        { type = "datasource", id = "loki",      name = "Loki",        version = "1.0.0" },
        { type = "panel",      id = "logs",       name = "Logs",        version = "" },
        { type = "panel",      id = "timeseries", name = "Time series", version = "" }
      ]
      annotations          = { list = [] }
      editable             = true
      fiscalYearStartMonth = 0
      graphTooltip         = 0
      id                   = null
      links                = []
      panels = [
        {
          datasource = { type = "loki", uid = "loki" }
          gridPos    = { h = 10, w = 24, x = 0, y = 0 }
          id         = 1
          options = {
            dedupStrategy      = "none"
            enableLogDetails   = true
            prettifyLogMessage = false
            showCommonLabels   = false
            showLabels         = false
            showTime           = false
            sortOrder          = "Descending"
            wrapLogMessage     = false
          }
          targets = [{ datasource = { type = "loki", uid = "loki" }, editorMode = "code", expr = "{namespace=\"wsc-app-log\"}", queryType = "range", refId = "A" }]
          title   = "Any Log"
          type    = "logs"
        },
        {
          datasource  = { type = "loki", uid = "loki" }
          fieldConfig = { defaults = { color = { mode = "palette-classic" } }, overrides = [] }
          gridPos     = { h = 8, w = 8, x = 0, y = 10 }
          id          = 2
          options = { legend = { calcs = [], displayMode = "list", placement = "bottom", showLegend = true }, tooltip = { mode = "single", sort = "none" } }
          targets = [{ datasource = { type = "loki", uid = "loki" }, editorMode = "code", expr = "count_over_time({namespace=\"wsc-app-log\"} |= \"INFO\" [1m])", queryType = "range", refId = "A" }]
          title   = "INFO Log Count"
          type    = "timeseries"
        },
        {
          datasource  = { type = "loki", uid = "loki" }
          fieldConfig = { defaults = { color = { mode = "palette-classic" } }, overrides = [] }
          gridPos     = { h = 8, w = 8, x = 8, y = 10 }
          id          = 3
          options = { legend = { calcs = [], displayMode = "list", placement = "bottom", showLegend = true }, tooltip = { mode = "single", sort = "none" } }
          targets = [{ datasource = { type = "loki", uid = "loki" }, editorMode = "code", expr = "count_over_time({namespace=\"wsc-app-log\"} |= \"ERROR\" [1m])", queryType = "range", refId = "A" }]
          title   = "ERROR Log Count"
          type    = "timeseries"
        },
        {
          datasource  = { type = "loki", uid = "loki" }
          fieldConfig = { defaults = { color = { mode = "palette-classic" } }, overrides = [] }
          gridPos     = { h = 8, w = 8, x = 16, y = 10 }
          id          = 4
          options = { legend = { calcs = [], displayMode = "list", placement = "bottom", showLegend = true }, tooltip = { mode = "single", sort = "none" } }
          targets = [{ datasource = { type = "loki", uid = "loki" }, editorMode = "code", expr = "count_over_time({namespace=\"wsc-app-log\"} |= \"WARNING\" [1m])", queryType = "range", refId = "A" }]
          title   = "WARNING Log Count"
          type    = "timeseries"
        }
      ]
      refresh       = "5s"
      schemaVersion = 39
      tags          = []
      time          = { from = "now-1h", to = "now" }
      timepicker    = {}
      timezone      = "browser"
      title         = "WSC2026 Container Logs"
      uid           = "wsc2026-container-logs"
      version       = 1
    })
  }

  depends_on = [helm_release.loki]
}

resource "helm_release" "grafana" {
  name             = "grafana"
  repository       = "https://grafana.github.io/helm-charts"
  chart            = "grafana"
  namespace        = "wsc-logging"
  create_namespace = false
  timeout          = 600

  values = [<<-YAML
    service:
      type: LoadBalancer
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-type: nlb
        service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
        service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing

    adminUser: "wsc2026-admin-${var.contestant_number}"
    adminPassword: "admin${var.contestant_number}!"

    datasources:
      datasources.yaml:
        apiVersion: 1
        datasources:
        - name: Loki
          type: loki
          uid: loki
          url: http://loki:3100
          access: proxy
          isDefault: true
          jsonData:
            maxLines: 1000

    dashboardProviders:
      dashboardproviders.yaml:
        apiVersion: 1
        providers:
        - name: default
          orgId: 1
          folder: ''
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards/default

    dashboardsConfigMaps:
      default: "grafana-dashboard-cm"
  YAML
  ]

  depends_on = [helm_release.loki, kubernetes_config_map.grafana_dashboard]
}
