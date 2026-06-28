resource "kubernetes_namespace" "skills_sqs" {
  metadata {
    name = "skills-sqs"
  }
}

resource "kubernetes_service_account" "worker" {
  metadata {
    name      = "skills-sqs-worker-sa"
    namespace = kubernetes_namespace.skills_sqs.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.worker_role_arn
    }
  }
}

resource "kubernetes_deployment" "worker" {
  metadata {
    name      = "skills-sqs-worker"
    namespace = kubernetes_namespace.skills_sqs.metadata[0].name
  }

  spec {
    replicas = 0

    selector {
      match_labels = { app = "skills-sqs-worker" }
    }

    template {
      metadata {
        labels = { app = "skills-sqs-worker" }
      }

      spec {
        service_account_name = kubernetes_service_account.worker.metadata[0].name

        container {
          name  = "worker"
          image = "${var.ecr_repository_url}:latest"

          env {
            name  = "SQS_QUEUE_URL"
            value = var.sqs_queue_url
          }
          env {
            name  = "AWS_REGION"
            value = var.region
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_account.worker]
}

locals {
  kubeconfig_cmd = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"

  ec2_node_class_yaml = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: skills-sqs-nc
    spec:
      amiSelectorTerms:
        - alias: al2023@latest
      role: ${var.node_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      tags:
        karpenter.sh/discovery: ${var.cluster_name}
  YAML

  node_pool_yaml = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: skills-sqs-np
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: skills-sqs-nc
          requirements:
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64"]
            - key: node.kubernetes.io/instance-type
              operator: In
              values: ["t3.small", "t3.medium"]
      limits:
        cpu: "10"
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  trigger_auth_yaml = <<-YAML
    apiVersion: keda.sh/v1alpha1
    kind: TriggerAuthentication
    metadata:
      name: skills-sqs-trigger-auth
      namespace: skills-sqs
    spec:
      podIdentity:
        provider: aws
  YAML

  scaled_object_yaml = <<-YAML
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: skills-sqs-scaledobject
      namespace: skills-sqs
    spec:
      scaleTargetRef:
        name: skills-sqs-worker
      minReplicaCount: 0
      maxReplicaCount: 10
      triggers:
        - type: aws-sqs-queue
          authenticationRef:
            name: skills-sqs-trigger-auth
          metadata:
            queueURL: ${var.sqs_queue_url}
            queueLength: "1"
            awsRegion: ${var.region}
            identityOwner: operator
  YAML
}

resource "null_resource" "ec2_node_class" {
  provisioner "local-exec" {
    command = <<-EOT
      ${local.kubeconfig_cmd}
      cat <<'EOF' | kubectl apply -f -
      ${local.ec2_node_class_yaml}
      EOF
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [kubernetes_deployment.worker]
}

resource "null_resource" "node_pool" {
  provisioner "local-exec" {
    command = <<-EOT
      ${local.kubeconfig_cmd}
      cat <<'EOF' | kubectl apply -f -
      ${local.node_pool_yaml}
      EOF
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [null_resource.ec2_node_class]
}

resource "null_resource" "trigger_auth" {
  provisioner "local-exec" {
    command = <<-EOT
      ${local.kubeconfig_cmd}
      cat <<'EOF' | kubectl apply -f -
      ${local.trigger_auth_yaml}
      EOF
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [kubernetes_deployment.worker]
}

resource "null_resource" "scaled_object" {
  provisioner "local-exec" {
    command = <<-EOT
      ${local.kubeconfig_cmd}
      cat <<'EOF' | kubectl apply -f -
      ${local.scaled_object_yaml}
      EOF
    EOT
    interpreter = ["bash", "-c"]
  }

  depends_on = [null_resource.trigger_auth, kubernetes_deployment.worker]
}
