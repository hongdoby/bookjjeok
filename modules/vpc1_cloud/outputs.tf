output "vpc_id" {
  description = "생성된 VPC1의 ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "ALB 등이 사용할 퍼블릭 서브넷 ID 목록"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "EKS 클러스터가 위치할 내부 서브넷 ID 목록"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "cluster_name" {
  description = "EKS 클러스터 이름"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS 클러스터 API 엔드포인트"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS 클러스터 인증서 데이터"
  value       = module.eks.cluster_certificate_authority_data
}
