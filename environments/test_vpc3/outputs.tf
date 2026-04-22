output "bastion_public_ips" {
  description = "Bastion 퍼블릭 IP"
  value       = module.vpc3_shared.bastion_public_ips
}

output "alb_dns_name" {
  description = "ALB DNS"
  value       = module.vpc3_shared.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = module.vpc3_shared.rds_endpoint
}

output "rds_proxy_endpoint" {
  description = "RDS Proxy 엔드포인트"
  value       = module.vpc3_shared.rds_proxy_endpoint
}

output "redis_primary_endpoint" {
  description = "Redis 엔드포인트"
  value       = module.vpc3_shared.redis_primary_endpoint
}