# TargetGroupBinding: log-generator Service ↔ 위에서 만든 TG(o11y-app-tg) 연결.
# 컨트롤러가 Pod IP를 TG에 자동 등록하고, ALB SG -> Pod 8080 인바운드 규칙도 관리한다.
# CRD가 plan 시점에 없어도 되도록 kubectl_manifest 사용.
resource "kubectl_manifest" "app_tgb" {
  yaml_body = yamlencode({
    apiVersion = "elbv2.k8s.aws/v1beta1"
    kind       = "TargetGroupBinding"
    metadata = {
      name      = "${var.prefix}-app-tgb"
      namespace = kubernetes_namespace.o11y.metadata[0].name
    }
    spec = {
      serviceRef = {
        name = kubernetes_service.log_generator.metadata[0].name
        port = 80
      }
      targetGroupARN = aws_lb_target_group.app.arn
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
            port     = 8080
          }]
        }]
      }
    }
  })

  depends_on = [
    kubernetes_service.log_generator,
    aws_lb_target_group.app,
  ]
}
