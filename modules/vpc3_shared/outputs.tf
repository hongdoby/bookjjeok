########################################
# VPC
########################################

output "vpc3_id" {
  description = "VPC3 ID"
  value       = aws_vpc.vpc3.id
}

output "vpc3_cidr" {
  description = "VPC3 CIDR"
  value       = aws_vpc.vpc3.cidr_block
}

output "public_subnet_ids" {
  description = "퍼블릭 서브넷 IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "프라이빗 서브넷 IDs"
  value       = aws_subnet.private[*].id
}

########################################
# Bastion
########################################

output "bastion_public_ips" {
  description = "Bastion 퍼블릭 IP 목록"
  value       = aws_eip.bastion[*].public_ip
}

########################################
# ALB
########################################

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_target_group_arn" {
  description = "기본 타겟 그룹 ARN (타겟 등록 필요)"
  value       = aws_lb_target_group.default.arn
}

########################################
# RDS
########################################

output "rds_endpoint" {
  description = "RDS 엔드포인트 (직접 접속용)"
  value       = aws_db_instance.main.endpoint
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy 엔드포인트 (앱에서 사용)"
  value       = aws_db_proxy.main.endpoint
}

########################################
# ElastiCache Redis
########################################

output "redis_primary_endpoint" {
  description = "Redis Primary 엔드포인트"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "redis_reader_endpoint" {
  description = "Redis Reader 엔드포인트"
  value       = aws_elasticache_replication_group.main.reader_endpoint_address
}

########################################
# VPC Peering
########################################

# VPC1 올라오면 주석 해제
# output "vpc_peering_id" {
#   description = "VPC Peering Connection ID"
#   value       = aws_vpc_peering_connection.vpc3_to_vpc1.id
# }

########################################
# Security Group IDs (다른 모듈에서 참조용)
########################################

output "sg_bastion_id" {
  description = "Bastion Security Group ID"
  value       = aws_security_group.bastion.id
}

output "sg_alb_id" {
  description = "ALB Security Group ID"
  value       = aws_security_group.alb.id
}

output "sg_rds_id" {
  description = "RDS Security Group ID"
  value       = aws_security_group.rds.id
}

output "sg_rds_proxy_id" {
  description = "RDS Proxy Security Group ID"
  value       = aws_security_group.rds_proxy.id
}

output "sg_redis_id" {
  description = "ElastiCache Redis Security Group ID"
  value       = aws_security_group.redis.id
}
