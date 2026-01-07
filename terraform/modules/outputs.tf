output "release_name" {
  description = "Name of the Helm release"
  value       = helm_release.s3_sync_compress.name
}

output "release_namespace" {
  description = "Namespace where the release was deployed"
  value       = helm_release.s3_sync_compress.namespace
}

output "release_status" {
  description = "Status of the Helm release"
  value       = helm_release.s3_sync_compress.status
}

output "release_version" {
  description = "Version of the deployed chart"
  value       = helm_release.s3_sync_compress.version
}

output "deployment_name" {
  description = "Name of the Kubernetes Deployment"
  value       = "${var.release_name}-s3-sync-compress"
}

output "service_name" {
  description = "Name of the Kubernetes Service"
  value       = "${var.release_name}-s3-sync-compress"
}

output "pods_selector_labels" {
  description = "Labels used to select the pods"
  value = {
    "app.kubernetes.io/name"     = "s3-sync-compress"
    "app.kubernetes.io/instance" = var.release_name
  }
}
