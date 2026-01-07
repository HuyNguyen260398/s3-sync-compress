# S3 Sync Compress Terraform Module

A reusable Terraform module to deploy the S3 Sync Compress application to an existing EKS cluster using Helm.

## Features

- Deploys S3 Sync Compress Helm chart to pre-existing EKS cluster
- Configurable number of replicas with pod anti-affinity
- Support for custom Docker image repository and tag
- Configurable AWS credentials for S3 access
- Resource limits and requests configuration
- Optional namespace creation
- Wait for deployment to be ready

## Prerequisites

- Existing EKS cluster
- Helm 3.x installed
- Terraform >= 1.0
- AWS credentials configured
- Helm chart available at the specified path

## Usage

```hcl
module "s3_sync_compress" {
  source = "./modules/s3-sync-compress"

  cluster_name             = "my-eks-cluster"
  cluster_endpoint         = "https://my-cluster.eks.amazonaws.com"
  cluster_ca_certificate   = "LS0tLS1CRUdJTi..."
  cluster_region           = "ap-southeast-1"

  s3_bucket              = "my-s3-bucket"
  aws_access_key_id      = var.aws_access_key_id
  aws_secret_access_key  = var.aws_secret_access_key
  
  replica_count          = 3
  namespace              = "default"
  create_namespace       = false
  
  tags = {
    Environment = "production"
    Team        = "data-engineering"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `cluster_name` | Name of the EKS cluster | `string` | - | yes |
| `cluster_endpoint` | Endpoint of the EKS cluster | `string` | - | yes |
| `cluster_ca_certificate` | CA certificate of the EKS cluster | `string` | - | yes |
| `cluster_region` | AWS region of the EKS cluster | `string` | - | yes |
| `aws_access_key_id` | AWS Access Key ID | `string` | - | yes |
| `aws_secret_access_key` | AWS Secret Access Key | `string` | - | yes |
| `s3_bucket` | S3 bucket name for sync and compress | `string` | - | yes |
| `s3_prefix` | S3 prefix of the defined bucket | `string` | - | yes |
| `s3_output_bucket` | S3 output bucket name for sync and compress results | `string` | - | yes |
| `s3_output_prefix` | S3 output prefix of the defined output bucket | `string` | - | yes |
| `chart_path` | Path to the Helm chart | `string` | `../../helm/s3-sync-compress` | no |
| `namespace` | Kubernetes namespace to deploy to | `string` | `default` | no |
| `release_name` | Helm release name | `string` | `s3-sync-compress` | no |
| `replica_count` | Number of pod replicas | `number` | `3` | no |
| `image_repository` | Docker image repository | `string` | `huynguyen260398/s3-sync-compress` | no |
| `image_tag` | Docker image tag | `string` | `latest` | no |
| `aws_region` | AWS region for S3 | `string` | `ap-southeast-1` | no |
| `pod_anti_affinity_type` | Pod anti-affinity type | `string` | `preferred` | no |
| `service_type` | Kubernetes Service type | `string` | `ClusterIP` | no |
| `cpu_request` | CPU request for pods | `string` | `250m` | no |
| `cpu_limit` | CPU limit for pods | `string` | `500m` | no |
| `memory_request` | Memory request for pods | `string` | `256Mi` | no |
| `memory_limit` | Memory limit for pods | `string` | `512Mi` | no |
| `create_namespace` | Whether to create the namespace | `bool` | `false` | no |
| `tags` | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `release_name` | Name of the Helm release |
| `release_namespace` | Namespace where the release was deployed |
| `release_status` | Status of the Helm release |
| `release_version` | Version of the deployed chart |
| `deployment_name` | Name of the Kubernetes Deployment |
| `service_name` | Name of the Kubernetes Service |
| `pods_selector_labels` | Labels used to select the pods |

## Example

See the `examples/` directory for a complete example of how to use this module with actual EKS cluster data.

## Notes

- AWS credentials must have permissions for S3 bucket operations
- The module uses pod anti-affinity to distribute pods across nodes when possible
- The deployment waits for the pods to be ready with a 5-minute timeout
- Sensitive variables (credentials) are marked as sensitive and won't be shown in output
