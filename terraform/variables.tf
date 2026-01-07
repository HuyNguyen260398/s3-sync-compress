variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "eks_cluster_name" {
  description = "Name of the existing EKS cluster"
  type        = string
}

variable "s3_source_bucket" {
  description = "S3 bucket name to sync from"
  type        = string
}

variable "s3_source_prefix" {
  description = "S3 prefix/path to sync from"
  type        = string
  default     = ""
}

variable "s3_output_bucket" {
  description = "S3 bucket name to save compressed files"
  type        = string
}

variable "s3_output_prefix" {
  description = "S3 prefix/path to save compressed files"
  type        = string
  default     = ""
}

variable "app_aws_access_key_id" {
  description = "AWS access key ID for the application (should have S3 permissions)"
  type        = string
  sensitive   = true
}

variable "app_aws_secret_access_key" {
  description = "AWS secret access key for the application"
  type        = string
  sensitive   = true
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "s3-sync-compress"
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for deployment"
  type        = string
  default     = "default"
}

variable "create_namespace" {
  description = "Create namespace if it doesn't exist"
  type        = bool
  default     = false
}

variable "replica_count" {
  description = "Number of pod replicas"
  type        = number
  default     = 3

  validation {
    condition     = var.replica_count > 0
    error_message = "replica_count must be greater than 0."
  }
}

variable "pod_anti_affinity_type" {
  description = "Pod anti-affinity type: required or preferred"
  type        = string
  default     = "required"

  validation {
    condition     = contains(["required", "preferred"], var.pod_anti_affinity_type)
    error_message = "pod_anti_affinity_type must be either 'required' or 'preferred'."
  }
}

variable "service_type" {
  description = "Kubernetes service type"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "service_type must be one of: ClusterIP, NodePort, LoadBalancer."
  }
}

variable "cpu_request" {
  description = "CPU request for pods"
  type        = string
  default     = "250m"
}

variable "cpu_limit" {
  description = "CPU limit for pods"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request for pods"
  type        = string
  default     = "256Mi"
}

variable "memory_limit" {
  description = "Memory limit for pods"
  type        = string
  default     = "512Mi"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "s3-sync-compress"
    Environment = "production"
  }
}
