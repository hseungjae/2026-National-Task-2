output "karpenter_release" {
  value = helm_release.karpenter.name
}

output "keda_release" {
  value = helm_release.keda.name
}
