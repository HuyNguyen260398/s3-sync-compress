# S3 Sync & Compress Utility

A single containerized service that automatically synchronizes files from AWS S3, compresses them using gzip, and serves the results through a modern web interface powered by nginx - all in one container!

## Key Features

- Single Container Architecture: Nginx, AWS CLI, Python, and automation scripts all in one image
- Automated S3 Sync: Downloads files from specified S3 bucket and prefix
- File Compression: Compresses downloaded files using gzip for storage efficiency
- Integrated Web Interface: Beautiful, responsive web UI served by nginx
- Real-time Status: Live status monitoring with auto-refresh
- Health Monitoring: Built-in health checks and endpoint monitoring
- Docker Optimized: Single image deployment with multi-stage architecture
- Kubernetes Ready: Includes production-grade Helm chart for K8s deployment
- Infrastructure as Code: Terraform module for automated AWS EKS deployment

## Quick Start

### Prerequisites

- Docker (20.10+)
- Docker Compose (optional, for easier management)
- AWS credentials with S3 access permissions

### Option 1: Docker Run (Direct)

```bash
# Build the image
docker build -t s3-sync-compress:latest .

# Run the service
docker run -p 8080:80 \
  -e AWS_ACCESS_KEY_ID='your-access-key' \
  -e AWS_SECRET_ACCESS_KEY='your-secret-key' \
  -e S3_BUCKET='your-bucket-name' \
  -e S3_PREFIX='optional/prefix/' \
  -e S3_OUTPUT_BUCKET='your-output-bucket-name' \
  -e S3_OUTPUT_PREFIX='optional/output-prefix/' \
  -e AWS_DEFAULT_REGION='ap-southeast-1' \
  --name s3-sync-service \
  s3-sync-compress:latest
```

### Option 2: Docker Compose (Recommended)

```bash
# Configure environment in a .env file or export variables

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f
```

## Access Points

Once running, access the service at:

- **Main Web UI**: http://localhost:8080

## Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AWS_ACCESS_KEY_ID` | AWS access key | - | Yes |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | - | Yes |
| `AWS_DEFAULT_REGION` | AWS region | `ap-southeast-1` | Yes |
| `S3_BUCKET` | S3 bucket name | - | Yes |
| `S3_PREFIX` | S3 object prefix/folder | - | No |
| `S3_OUTPUT_BUCKET` | S3 bucket name to save the compressed files | - | Yes |
| `S3_OUTPUT_PREFIX` | S3 object prefix/folder | - | No |

### Container Specifications

- Base Image: nginx:alpine
- Additional Packages: Python 3, bash, curl, jq
- Python Libraries: boto3, awscli, fastapi, uvicorn
- Exposed Port: 80
- Health Check: HTTP GET /health

## Kubernetes Deployment (Helm)

The project includes a production-grade Helm chart for deploying to Kubernetes clusters.

### Prerequisites

- Kubernetes cluster 1.14+ (local or cloud)
- Helm 3.x
- kubectl configured to access your cluster

### Quick Start with Local Kubernetes

If using Docker Desktop or Minikube:

```bash
# Verify Kubernetes is running
kubectl cluster-info

# Navigate to the Helm chart directory
cd helm/s3-sync-compress

# Install the Helm chart
helm install s3-sync-compress . \
  --set aws.s3Bucket=your-bucket-name \
  --set aws.s3Prefix=your-prefix \
  --set aws.s3OutputBucket=your-output-bucket \
  --set aws.s3OutputPrefix=output-prefix \
  --set aws.accessKeyId=YOUR_ACCESS_KEY \
  --set aws.secretAccessKey=YOUR_SECRET_KEY \
  --set aws.region=ap-southeast-1 \
  --set replicaCount=2 \
  --set service.type=NodePort
```

### Verify Deployment

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/name=s3-sync-compress

# View logs
kubectl logs -l app.kubernetes.io/name=s3-sync-compress

# Check service
kubectl get svc s3-sync-compress

# For NodePort, access at: http://localhost:<NODE_PORT>
```

### Helm Chart Configuration

The Helm chart is located in the `helm/s3-sync-compress` directory with the following structure:

- Chart.yaml: Chart metadata
- values.yaml: Default configuration values
- templates/deployment.yaml: Kubernetes Deployment with pod anti-affinity
- templates/service.yaml: Kubernetes Service
- templates/_helpers.tpl: Template helper functions

Key Helm values:

| Value | Description | Default |
|-------|-------------|---------|
| `replicaCount` | Number of pod replicas | 3 |
| `image.repository` | Docker image repository | huynguyen260398/s3-sync-compress |
| `image.tag` | Docker image tag | latest |
| `service.type` | Kubernetes service type | ClusterIP |
| `podAntiAffinity.enabled` | Enable pod anti-affinity | true |
| `podAntiAffinity.type` | Anti-affinity type (required/preferred) | required |
| `aws.s3Bucket` | Source S3 bucket | "" |
| `aws.s3Prefix` | Source S3 prefix | "" |
| `aws.s3OutputBucket` | Output S3 bucket | "" |
| `aws.s3OutputPrefix` | Output S3 prefix | "" |

### Upgrade or Uninstall

```bash
# Upgrade the release
helm upgrade s3-sync-compress . --set replicaCount=5

# Uninstall the release
helm uninstall s3-sync-compress
```

## AWS EKS Deployment (Terraform)

For production deployments to AWS EKS, use the provided Terraform module.

### Prerequisites

- Terraform 1.0+
- AWS credentials configured
- Existing EKS cluster
- Helm 3.x

### Module Location

The Terraform module is located at: `terraform/modules/s3-sync-compress`

### Basic Usage

The project includes ready-to-use Terraform configuration files in the `terraform/` directory:

- `main.tf` - Main configuration that calls the module
- `variables.tf` - Variable definitions
- `terraform.tfvars.example` - Example values file

**Steps to deploy:**

1. Copy the example values file:
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

2. Edit `terraform.tfvars` with your values:
```bash
# Update with your EKS cluster name and S3 buckets
nano terraform.tfvars  # or use your preferred editor
```

3. Configure AWS credentials:
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
# OR use aws configure
aws configure
```

The configuration automatically:
- Fetches your existing EKS cluster details
- Authenticates using AWS credentials
- Deploys the Helm chart to your cluster
- Configures all pod affinity and resource settings

### Variables Reference

Edit `terraform.tfvars` with your deployment configuration. All available variables:

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `aws_region` | string | No | ap-southeast-1 | AWS region |
| `eks_cluster_name` | string | Yes | - | Name of existing EKS cluster |
| `s3_source_bucket` | string | Yes | - | Source S3 bucket name |
| `s3_source_prefix` | string | No | "" | S3 source prefix |
| `s3_output_bucket` | string | Yes | - | Output S3 bucket |
| `s3_output_prefix` | string | No | "" | S3 output prefix |
| `app_aws_access_key_id` | string | Yes | - | AWS access key for application (sensitive) |
| `app_aws_secret_access_key` | string | Yes | - | AWS secret key for application (sensitive) |
| `release_name` | string | No | s3-sync-compress | Helm release name |
| `kubernetes_namespace` | string | No | default | Kubernetes namespace |
| `create_namespace` | bool | No | false | Create namespace if it doesn't exist |
| `replica_count` | number | No | 3 | Number of pod replicas |
| `pod_anti_affinity_type` | string | No | required | Pod anti-affinity (required/preferred) |
| `service_type` | string | No | ClusterIP | Service type (ClusterIP/NodePort/LoadBalancer) |
| `cpu_request` | string | No | 250m | Pod CPU request |
| `cpu_limit` | string | No | 500m | Pod CPU limit |
| `memory_request` | string | No | 256Mi | Pod memory request |
| `memory_limit` | string | No | 512Mi | Pod memory limit |
| `tags` | map(string) | No | {} | Resource tags |

### Deployment Steps

```bash
# Navigate to your Terraform directory
cd path/to/your/terraform

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Verify deployment
kubectl get pods -l app.kubernetes.io/name=s3-sync-compress
```

### Module Outputs

The module provides the following outputs:

```bash
# Get deployment information
terraform output deployment_info

# Get release name
terraform output -json | jq '.deployment_info.value.release_name'
```

Available outputs:

- `release_name`: Helm release name
- `release_namespace`: Deployment namespace
- `release_status`: Helm release status
- `deployment_name`: Kubernetes deployment name
- `service_name`: Kubernetes service name
- `pods_selector_labels`: Pod selector labels

### Module Features

- Automatic authentication to existing EKS cluster
- Optional Kubernetes namespace creation
- Pod anti-affinity for high availability
- Configurable resource limits and requests
- Sensitive variable handling (AWS credentials)
- Automatic deployment wait with timeout
- Atomic deployments with rollback on failure
- Comprehensive documentation and examples

### Destroy Infrastructure

```bash
# Destroy the deployment
terraform destroy
```

## License

This project is provided as-is for demonstration purposes. Suitable for production use with proper configuration and security measures.