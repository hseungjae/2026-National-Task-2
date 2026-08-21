provider "aws" {
  region  = var.region
  profile = var.awscli_profile
}

provider "helm" {
  kubernetes = {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "C:/Program Files/Amazon/AWSCLIV2/aws.exe"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "C:/Program Files/Amazon/AWSCLIV2/aws.exe"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}