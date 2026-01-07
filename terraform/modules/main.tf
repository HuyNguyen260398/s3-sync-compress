terraform {
  experiments = [module_variable_optional_attrs]
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

# Create namespace if specified
resource "kubernetes_namespace" "s3_sync_compress" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace

    labels = merge(
      var.tags,
      {
        "app" = "s3-sync-compress"
      }
    )
  }

  depends_on = []
}

# Deploy Helm chart
resource "helm_release" "s3_sync_compress" {
  name             = var.release_name
  namespace        = var.namespace
  chart            = var.chart_path
  create_namespace = !var.create_namespace

  set {
    name  = "replicaCount"
    value = var.replica_count
  }

  set {
    name  = "image.repository"
    value = var.image_repository
  }

  set {
    name  = "image.tag"
    value = var.image_tag
  }

  set {
    name  = "aws.s3Bucket"
    value = var.s3_bucket
  }

  set {
    name  = "aws.accessKeyId"
    value = var.aws_access_key_id
  }

  set {
    name  = "aws.secretAccessKey"
    value = var.aws_secret_access_key
  }

  set {
    name  = "aws.region"
    value = var.aws_region
  }

  set {
    name  = "podAntiAffinity.type"
    value = var.pod_anti_affinity_type
  }

  set {
    name  = "service.type"
    value = var.service_type
  }

  set {
    name  = "resources.requests.cpu"
    value = var.cpu_request
  }

  set {
    name  = "resources.limits.cpu"
    value = var.cpu_limit
  }

  set {
    name  = "resources.requests.memory"
    value = var.memory_request
  }

  set {
    name  = "resources.limits.memory"
    value = var.memory_limit
  }

  # Wait for deployment to be ready
  wait       = true
  timeout    = 300
  atomic     = true
  skip_crds  = false

  depends_on = [
    kubernetes_namespace.s3_sync_compress
  ]
}
