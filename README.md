# 🚀 S3 Sync & Compress Service (Unified Container)

A **single containerized service** that automatically synchronizes files from AWS S3, compresses them using gzip, and serves the results through a modern web interface powered by nginx - all in one container!

## ✨ Key Features

- **🏗️ Single Container Architecture**: Nginx, AWS CLI, Python, and automation scripts all in one image
- **📦 Automated S3 Sync**: Downloads files from specified S3 bucket and prefix
- **🗜️ File Compression**: Compresses downloaded files using gzip for storage efficiency
- **🌐 Integrated Web Interface**: Beautiful, responsive web UI served by nginx
- **📊 Real-time Status**: Live status monitoring with auto-refresh
- **🔍 Health Monitoring**: Built-in health checks and endpoint monitoring
- **🐳 Docker Optimized**: Single image deployment with multi-stage architecture
- **🔄 Process Management**: Automatic service orchestration within container

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Single Docker Container                               │
│                                                                                 │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐    │
│  │             │    │             │    │             │    │             │    │
│  │  Nginx      │    │   Python    │    │  AWS CLI    │    │  Bash       │    │
│  │  Web Server │◄───┤   S3 Sync   │◄───┤  Tools      │◄───┤  Scripts    │    │
│  │             │    │   Script    │    │             │    │             │    │
│  └─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘    │
│         │                   │                    │                    │       │
│         └───────────────────┼────────────────────┼────────────────────┘       │
│                             │                    │                            │
│                    ┌─────────────────┐  ┌─────────────────┐                   │
│                    │  Shared Storage │  │   Port 80       │                   │
│                    │  (/app/output)  │  │ (Web Interface) │                   │
│                    └─────────────────┘  └─────────────────┘                   │
└─────────────────────────────────────────────────────────────────────────────────┘
                                         │
                              ┌─────────────────┐
                              │    Port 8080    │
                              │  (Host Mapping) │
                              └─────────────────┘
```

## 🚀 Quick Start

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
  -e AWS_DEFAULT_REGION='us-east-1' \
  --name s3-sync-service \
  s3-sync-compress:latest
```

### Option 2: Docker Compose (Recommended)

```bash
# Configure environment
cp .env.example .env
# Edit .env with your AWS credentials

# Start the service
docker-compose up -d

# View logs
docker-compose logs -f
```

### Option 3: Make Commands

```bash
make build     # Build the image
make up        # Start with docker-compose
make run       # Start with direct docker run
make test      # Test all endpoints
make logs      # View logs
make status    # Check service status
```

## 🎛️ Access Points

Once running, access the service at:

- **🏠 Main Dashboard**: http://localhost:8080
- **📊 Status API**: http://localhost:8080/status
- **❤️ Health Check**: http://localhost:8080/health
- **📁 File API**: http://localhost:8080/api/files

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `AWS_ACCESS_KEY_ID` | AWS access key | - | ✅ |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key | - | ✅ |
| `AWS_DEFAULT_REGION` | AWS region | `ap-southeast-1` | ✅ |
| `S3_BUCKET` | S3 bucket name | `test-bucket` | ✅ |
| `S3_PREFIX` | S3 object prefix/folder | `` | ❌ |

### Container Specifications

- **Base Image**: nginx:alpine
- **Additional Packages**: Python 3, AWS CLI, bash, curl, jq
- **Python Libraries**: boto3, awscli
- **Exposed Port**: 80
- **Health Check**: HTTP GET /health

## 📊 Container Process Management

The unified container runs multiple processes:

1. **Entrypoint Script** (`/app/scripts/entrypoint.sh`):
   - Initializes services
   - Starts nginx in background
   - Executes S3 sync process
   - Monitors and maintains services

2. **S3 Sync Process** (`/app/scripts/init.sh` + Python script):
   - Validates AWS credentials
   - Downloads files from S3
   - Compresses files
   - Updates status in real-time

3. **Nginx Web Server**:
   - Serves web interface
   - Provides API endpoints
   - Serves compressed files
   - Health check endpoint

## 🏃‍♂️ Usage Examples

### Basic S3 Sync
```bash
# Sync entire bucket
export S3_BUCKET="my-data-bucket"
docker-compose up
```

### Sync Specific Prefix
```bash
# Sync only files from specific folder
export S3_BUCKET="my-data-bucket"
export S3_PREFIX="data/exports/2024/"
docker-compose up
```

### Production Deployment
```bash
# Build and run in detached mode
make build
make up

# Monitor the service
make status
make logs
```

### Testing and Debugging
```bash
# Run comprehensive tests
make test

# Check service health
curl http://localhost:8080/health

# Get detailed status
curl http://localhost:8080/status | jq .

# Access container shell
make exec
```

## 📈 Monitoring & Status

The service provides comprehensive monitoring:

### Status Information
```json
{
  "status": "completed",
  "files_synced": 25,
  "files_compressed": 25,
  "timestamp": "2024-01-07T10:30:00Z",
  "message": "Successfully processed 25 files, compressed 25"
}
```

### Health Check Response
```
HTTP/1.1 200 OK
healthy
```

### Container Health
```bash
# Check container health
docker inspect s3-sync-web-service --format '{{.State.Health.Status}}'
```

## 🐛 Troubleshooting

### Common Issues

1. **Container Won't Start**:
   ```bash
   # Check logs
   docker logs s3-sync-web-service
   
   # Verify image build
   docker images s3-sync-compress
   ```

2. **AWS Connection Issues**:
   ```bash
   # Test AWS credentials inside container
   docker exec s3-sync-web-service aws sts get-caller-identity
   
   # Check environment variables
   docker exec s3-sync-web-service env | grep AWS
   ```

3. **Service Not Responding**:
   ```bash
   # Check process status inside container
   docker exec s3-sync-web-service ps aux
   
   # Test nginx configuration
   docker exec s3-sync-web-service nginx -t
   ```

### Debugging Commands

```bash
# Full container inspection
make inspect

# Container shell access
make exec

# Service endpoint testing
make test

# Real-time logs
docker logs -f s3-sync-web-service
```

## 🚢 Production Considerations

### Resource Limits
```yaml
version: '3.8'
services:
  s3-sync-web:
    deploy:
      resources:
        limits:
          memory: 1G
          cpus: '1.0'
        reservations:
          memory: 512M
          cpus: '0.5'
```

### Security Best Practices
- Use AWS IAM roles instead of access keys when possible
- Run container with non-root user in production
- Use secrets management for AWS credentials
- Enable TLS/HTTPS for production deployments

### High Availability
- Deploy behind load balancer
- Use external storage for persistent data
- Implement container restart policies
- Monitor with external health checks

## 📦 Container Image Details

- **Size**: ~150MB (optimized Alpine-based)
- **Layers**: Multi-stage build for minimal footprint
- **Security**: Regular base image updates
- **Platforms**: linux/amd64, linux/arm64

## 📄 License

This project is provided as-is for demonstration purposes. Suitable for production use with proper configuration and security measures.