variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "CA certificate of the EKS cluster"
  type        = string
  sensitive   = true
}

variable "cluster_region" {
  description = "AWS region of the EKS cluster"
  type        = string
}

variable "chart_path" {
  description = "Path to the Helm chart"
  type        = string
  default     = "../../helm"
}

variable "namespace" {
  description = "Kubernetes namespace to deploy to"
  type        = string
  default     = "default"
}

variable "release_name" {
  description = "Helm release name"
  type        = string
  default     = "s3-sync-compress"
}

variable "replica_count" {
  description = "Number of pod replicas"
  type        = number
  default     = 3
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
  default     = "huynguyen260398/s3-sync-compress"
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for S3 operations"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for S3 operations"
  type        = string
  sensitive   = true
}

variable "aws_region" {
  description = "AWS region for S3"
  type        = string
  default     = "ap-southeast-1"
}

variable "s3_bucket" {
  description = "S3 bucket name for sync and compress"
  type        = string
}

variable "s3_prefix" {
  description = "S3 prefix of the defined bucket"
  type        = string
}

variable "s3_output_bucket" {
  description = "S3 output bucket name for sync and compress results"
  type        = string
}

variable "s3_output_prefix" {
  description = "S3 output prefix of the defined output bucket"
  type        = string
}

variable "pod_anti_affinity_type" {
  description = "Pod anti-affinity type: 'required' or 'preferred'"
  type        = string
  default     = "preferred"

  validation {
    condition     = contains(["required", "preferred"], var.pod_anti_affinity_type)
    error_message = "pod_anti_affinity_type must be either 'required' or 'preferred'."
  }
}

variable "service_type" {
  description = "Kubernetes Service type"
  type        = string
  default     = "ClusterIP"

  validation {
    condition     = contains(["ClusterIP", "NodePort", "LoadBalancer"], var.service_type)
    error_message = "service_type must be one of: ClusterIP, NodePort, or LoadBalancer."
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

variable "create_namespace" {
  description = "Whether to create the namespace"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
