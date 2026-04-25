output "cluster_endpoint" {
  description = "VPC1 EKS 클러스터 Endpoint"
  value       = module.vpc1_cloud.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "VPC1 EKS 클러스터 CA 데이터"
  value       = module.vpc1_cloud.cluster_certificate_authority_data
}

output "cluster_name" {
  description = "VPC1 EKS 클러스터 이름"
  value       = var.vpc1_cluster_name
}
