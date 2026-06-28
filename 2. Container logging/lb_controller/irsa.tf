module "aws-lb-controller-irsa-role"{
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts"
  name = "${var.prefix}-aws-lb-controller-sa-role"

  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
        provider_arn = var.eks_oidc_provider_arn
        namespace_service_accounts = ["kube-system:aws-lb-controller-sa"]
    }
  }
}