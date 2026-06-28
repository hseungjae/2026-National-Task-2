output "karpenter_release_name" {
  value = helm_release.karpenter.name
}

output "keda_release_name" {
  value = helm_release.keda.name
}
