resource "kubernetes_namespace" "scaling" {
  metadata {
    name = "wsc-scaling"
  }
}

resource "kubernetes_deployment" "scaling" {
  metadata {
    name      = "wsc-scaling-deploy"
    namespace = kubernetes_namespace.scaling.metadata[0].name
    labels = {
      dedicated = "scaling"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        dedicated = "scaling"
      }
    }

    template {
      metadata {
        labels = {
          dedicated = "scaling"
        }
      }

      spec {
        container {
          name    = "busybox"
          image   = "busybox:latest"
          command = ["sleep", "infinity"]

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_namespace.scaling]
}

locals {
  kubeconfig_cmd = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"

  ec2_node_class_yaml = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2023
      role: ${var.node_role_name}
      subnetSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
      - tags:
          karpenter.sh/discovery: ${var.cluster_name}
      amiSelectorTerms:
      - alias: al2023@latest
  YAML

  node_pool_yaml = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
          - key: kubernetes.io/arch
            operator: In
            values: ["amd64"]
          - key: karpenter.sh/capacity-type
            operator: In
            values: ["on-demand"]
          - key: node.kubernetes.io/instance-type
            operator: In
            values: ["t3.medium", "t3.large", "t3.xlarge"]
      limits:
        cpu: 100
        memory: 200Gi
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
  YAML

  scaled_object_yaml = <<-YAML
    apiVersion: keda.sh/v1alpha1
    kind: ScaledObject
    metadata:
      name: wsc-scaling-scaledobject
      namespace: wsc-scaling
    spec:
      scaleTargetRef:
        name: wsc-scaling-deploy
      pollingInterval: 30
      cooldownPeriod: 30
      minReplicaCount: 2
      maxReplicaCount: 100
      triggers:
      - type: aws-sqs-queue
        metadata:
          queueURL: ${var.sqs_queue_url}
          queueLength: "5"
          awsRegion: ${var.region}
          identityOwner: operator
  YAML
}

