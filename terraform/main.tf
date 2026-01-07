terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Fetch existing EKS cluster
data "aws_eks_cluster" "main" {
  name = var.eks_cluster_name
}

# Deploy S3 Sync Compress using the module
module "s3_sync_compress" {
  source = "./modules/s3-sync-compress"

  # EKS Cluster Configuration
  cluster_name           = data.aws_eks_cluster.main.name
  cluster_endpoint       = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = data.aws_eks_cluster.main.certificate_authority[0].data
  cluster_region         = var.aws_region

  # S3 Configuration
  s3_bucket             = var.s3_source_bucket
  s3_prefix             = var.s3_source_prefix
  s3_output_bucket      = var.s3_output_bucket
  s3_output_prefix      = var.s3_output_prefix

  # AWS Credentials for the application
  aws_access_key_id     = var.app_aws_access_key_id
  aws_secret_access_key = var.app_aws_secret_access_key

  # Deployment Configuration
  release_name           = var.release_name
  namespace              = var.kubernetes_namespace
  create_namespace       = var.create_namespace
  replica_count          = var.replica_count
  pod_anti_affinity_type = var.pod_anti_affinity_type
  service_type           = var.service_type

  # Resource Configuration
  cpu_request    = var.cpu_request
  cpu_limit      = var.cpu_limit
  memory_request = var.memory_request
  memory_limit   = var.memory_limit

  # Tags
  tags = var.tags
}

# Outputs
output "deployment_info" {
  description = "S3 Sync Compress deployment information"
  value = {
    release_name           = module.s3_sync_compress.release_name
    release_namespace      = module.s3_sync_compress.release_namespace
    release_status         = module.s3_sync_compress.release_status
    deployment_name        = module.s3_sync_compress.deployment_name
    service_name           = module.s3_sync_compress.service_name
    pods_selector_labels   = module.s3_sync_compress.pods_selector_labels
  }
}

output "eks_cluster_info" {
  description = "EKS cluster information"
  value = {
    cluster_name = data.aws_eks_cluster.main.name
    endpoint     = data.aws_eks_cluster.main.endpoint
    region       = var.aws_region
  }
}
