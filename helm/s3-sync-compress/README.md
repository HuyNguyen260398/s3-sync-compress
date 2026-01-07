# Helm Chart for S3 Sync Compress

This is the Helm chart for deploying the S3 Sync Compress application to Kubernetes clusters.

## Prerequisites

- Kubernetes 1.14+
- Helm 3.x

## Installation

Add the chart to your Helm repository or use it directly:

```bash
helm install s3-sync-compress . \
  --namespace default \
  --set aws.s3Bucket=your-bucket \
  --set aws.s3Prefix=your-prefix \
  --set aws.s3OutputBucket=output-bucket \
  --set aws.s3OutputPrefix=output-prefix \
  --set aws.accessKeyId=YOUR_KEY \
  --set aws.secretAccessKey=YOUR_SECRET
```

## Configuration

The following table lists the main configurable parameters of the chart:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of pod replicas | 3 |
| `image.repository` | Docker image repository | huynguyen260398/s3-sync-compress |
| `image.tag` | Docker image tag | latest |
| `image.pullPolicy` | Image pull policy | IfNotPresent |
| `service.type` | Service type | ClusterIP |
| `service.port` | Service port | 80 |
| `service.targetPort` | Container target port | 80 |
| `aws.s3Bucket` | Source S3 bucket name | "" |
| `aws.s3Prefix` | Source S3 prefix/path | "" |
| `aws.s3OutputBucket` | Output S3 bucket name | "" |
| `aws.s3OutputPrefix` | Output S3 prefix/path | "" |
| `aws.region` | AWS region | ap-southeast-1 |
| `aws.accessKeyId` | AWS access key ID | "" |
| `aws.secretAccessKey` | AWS secret access key | "" |
| `podAntiAffinity.enabled` | Enable pod anti-affinity | true |
| `podAntiAffinity.type` | Anti-affinity type (required/preferred) | required |
| `resources.requests.cpu` | CPU request | 250m |
| `resources.requests.memory` | Memory request | 256Mi |
| `resources.limits.cpu` | CPU limit | 500m |
| `resources.limits.memory` | Memory limit | 512Mi |
| `healthCheck.enabled` | Enable health checks | true |
| `healthCheck.initialDelaySeconds` | Health check initial delay | 15 |
| `healthCheck.periodSeconds` | Health check period | 30 |
| `healthCheck.timeoutSeconds` | Health check timeout | 10 |
| `healthCheck.failureThreshold` | Health check failure threshold | 3 |
| `nodeSelector` | Node selector labels | test-nodes: true |
| `create_namespace` | Create namespace if it doesn't exist | false |
| `tags` | Additional labels/tags for resources | {} |

## Examples

### Basic Installation with Required Values

```bash
helm install s3-sync-compress . \
  --set aws.s3Bucket=my-bucket \
  --set aws.s3OutputBucket=my-output \
  --set aws.accessKeyId=AKIA... \
  --set aws.secretAccessKey=...
```

### Increase Replicas

```bash
helm install s3-sync-compress . \
  --set replicaCount=5 \
  --set aws.s3Bucket=my-bucket \
  --set aws.s3OutputBucket=my-output \
  --set aws.accessKeyId=AKIA... \
  --set aws.secretAccessKey=...
```

### Use LoadBalancer Service

```bash
helm install s3-sync-compress . \
  --set service.type=LoadBalancer \
  --set aws.s3Bucket=my-bucket \
  --set aws.s3OutputBucket=my-output \
  --set aws.accessKeyId=AKIA... \
  --set aws.secretAccessKey=...
```

### With Custom Namespace

```bash
helm install s3-sync-compress . \
  --namespace s3-sync \
  --create-namespace \
  --set aws.s3Bucket=my-bucket \
  --set aws.s3OutputBucket=my-output \
  --set aws.accessKeyId=AKIA... \
  --set aws.secretAccessKey=...
```

### Upgrade Release

```bash
helm upgrade s3-sync-compress . \
  --set replicaCount=4 \
  --set aws.s3Bucket=my-bucket \
  --set aws.s3OutputBucket=my-output \
  --set aws.accessKeyId=AKIA... \
  --set aws.secretAccessKey=...
```

### Uninstall Release

```bash
helm uninstall s3-sync-compress
```

## Verification

Check deployment status:

```bash
kubectl get deployments -l app.kubernetes.io/name=s3-sync-compress
```

Check pod status:

```bash
kubectl get pods -l app.kubernetes.io/name=s3-sync-compress
```

View pod logs:

```bash
kubectl logs -l app.kubernetes.io/name=s3-sync-compress -f
```

Check service:

```bash
kubectl get svc s3-sync-compress
```

Describe deployment:

```bash
kubectl describe deployment s3-sync-compress
```

## Troubleshooting

### Pods not starting

Check pod events:

```bash
kubectl describe pod <pod-name>
```

View logs:

```bash
kubectl logs <pod-name>
```

Check resource availability:

```bash
kubectl describe nodes
```

### Node affinity errors

If pods show "node affinity mismatch" errors, ensure:

1. At least 3 nodes exist in the cluster (for pod anti-affinity with required type)
2. Or change pod anti-affinity type to preferred:

```bash
helm upgrade s3-sync-compress . \
  --set podAntiAffinity.type=preferred
```

### AWS credentials errors

Verify AWS credentials are correct:

```bash
kubectl get secret -A | grep aws
```

Check if credentials have S3 permissions on the specified buckets.

### Pod anti-affinity issues

For single-node clusters, use preferred anti-affinity:

```bash
helm install s3-sync-compress . \
  --set podAntiAffinity.type=preferred \
  --set aws.s3Bucket=my-bucket \
  --set aws.s3OutputBucket=my-output \
  --set aws.accessKeyId=AKIA... \
  --set aws.secretAccessKey=...
```

## Chart Structure

```
.
├── Chart.yaml               # Chart metadata
├── values.yaml              # Default values
├── README.md                # This file
└── templates/
    ├── deployment.yaml      # Kubernetes Deployment
    ├── service.yaml         # Kubernetes Service
    └── _helpers.tpl         # Template helpers
```

## Support

For detailed information about values, see `values.yaml`.

For Kubernetes deployment options, see `templates/`.

For the main project documentation, see the root `README.md`.
