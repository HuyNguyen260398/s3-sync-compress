provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes = {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

resource "kubernetes_namespace_v1" "s3_sync_compress" {
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
}

resource "helm_release" "s3_sync_compress" {
  name             = var.release_name
  namespace        = var.namespace
  chart            = var.chart_path
  create_namespace = !var.create_namespace

  set = [
    {
      name  = "replicaCount"
      value = var.replica_count
    },
    {
      name  = "image.repository"
      value = var.image_repository
    },
    {
      name  = "image.tag"
      value = var.image_tag
    },
    {
      name  = "aws.s3Bucket"
      value = var.s3_bucket
    },
    {
      name  = "aws.s3Prefix"
      value = var.s3_prefix
    },
    {
      name  = "aws.s3OutputBucket"
      value = var.s3_output_bucket
    },
    {
      name  = "aws.s3OutputPrefix"
      value = var.s3_output_prefix
    },
    {
      name  = "aws.accessKeyId"
      value = var.aws_access_key_id
    },
    {
      name  = "aws.secretAccessKey"
      value = var.aws_secret_access_key
    },
    {
      name  = "aws.region"
      value = var.aws_region
    },
    {
      name  = "podAntiAffinity.type"
      value = var.pod_anti_affinity_type
    },
    {
      name  = "service.type"
      value = var.service_type
    },
    {
      name  = "resources.requests.cpu"
      value = var.cpu_request
    },
    {
      name  = "resources.limits.cpu"
      value = var.cpu_limit
    },
    {
      name  = "resources.requests.memory"
      value = var.memory_request
    },
    {
      name  = "resources.limits.memory"
      value = var.memory_limit
    }
  ]

  wait       = true
  timeout    = 300
  atomic     = true
  skip_crds  = false

  depends_on = [
    kubernetes_namespace_v1.s3_sync_compress
  ]
}
