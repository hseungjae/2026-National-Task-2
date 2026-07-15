# TargetGroupBinding: o11y-grafana Service ↔ o11y-grafana-tg 연결
resource "kubectl_manifest" "grafana_tgb" {
  yaml_body = yamlencode({
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "${var.prefix}-grafana-tgb"
      namespace = var.monitoring_namespace
    }
    spec = {
      serviceRef = {
        name = "o11y-grafana"
        port = 80
      }
      targetGroupARN = aws_lb_target_group.grafana.arn
      targetType     = "ip"
      networking = {
        ingress = [{
          from = [{
            securityGroup = {
              groupID = aws_security_group.alb.id
            }
          }]
          ports = [{
            protocol = "TCP"
            port     = 3000
          }]
        }]
      }
    }
  })

  depends_on = [
    helm_release.grafana,
    aws_lb_target_group.grafana,
  ]
}
