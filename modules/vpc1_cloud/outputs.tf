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
