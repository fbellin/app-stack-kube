output "region" {
  description = "AWS region"
  value       = var.aws_region
}

output "cluster_id" {
  description = "EKS cluster ID."
  value       = module.eks.cluster_id
}


output "cluster_name" {
  description = "Kubernetes Cluster Name"
  value       = var.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane."
  value       = module.eks.cluster_endpoint
}
output "config_map_aws_auth" {
  description = "A kubernetes configuration to authenticate to this EKS cluster."
  value       = module.eks.config_map_aws_auth
}
