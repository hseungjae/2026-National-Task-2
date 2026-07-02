data "http" "karpenter_cf" {
  url = "https://raw.githubusercontent.com/aws/karpenter-provider-aws/v${var.karpenter_version}/website/content/en/preview/getting-started/getting-started-with-karpenter/cloudformation.yaml"
}

resource "aws_cloudformation_stack" "karpenter" {
  name          = var.cluster_name
  template_body = data.http.karpenter_cf.response_body
  capabilities  = ["CAPABILITY_NAMED_IAM"]

  parameters = {
    ClusterName = var.cluster_name
  }
}