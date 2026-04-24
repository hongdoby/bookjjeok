data "aws_caller_identity" "current" {}

locals {
  peer_owner_id = var.peer_owner_id != "" ? var.peer_owner_id : data.aws_caller_identity.current.account_id
}

#========================================
# VPC Peering Connection (VPC1 <-> VPC3)
#========================================
resource "aws_vpc_peering_connection" "vpc1_to_vpc3" {
  vpc_id        = var.vpc1_id
  peer_vpc_id   = var.vpc3_id
  peer_owner_id = local.peer_owner_id

  auto_accept = true

  tags = {
    Name = "${var.prefix}-vpc1-to-vpc3"
    Side = "both"
  }
}

resource "aws_vpc_peering_connection_options" "vpc1_to_vpc3" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc3.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

# (Optional) Accepter if auto_accept doesn't work cross-account.
# In this architecture, they are in the same account (same region ap-northeast-2).

#========================================
# Route Table Entries - VPC1
#========================================
resource "aws_route" "vpc1_public_to_vpc3" {
  route_table_id            = var.vpc1_public_route_table_id
  destination_cidr_block    = var.vpc3_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc3.id
}

resource "aws_route" "vpc1_private_to_vpc3" {
  route_table_id            = var.vpc1_private_route_table_id
  destination_cidr_block    = var.vpc3_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc3.id
}

#========================================
# Route Table Entries - VPC3
#========================================
resource "aws_route" "vpc3_public_to_vpc1" {
  route_table_id            = var.vpc3_public_route_table_id
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc3.id
}

resource "aws_route" "vpc3_private_to_vpc1" {
  count = length(var.vpc3_private_route_table_ids)

  route_table_id            = var.vpc3_private_route_table_ids[count.index]
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc3.id
}

#========================================
# Security Group Ingress Rules - VPC3
# VPC1 (BE Pods) -> VPC3 (RDS Proxy, Redis)
#========================================
resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_vpc1" {
  security_group_id = var.vpc3_sg_rds_proxy_id
  description       = "PostgreSQL from VPC1 backend pods"
  from_port         = 5432
  to_port           = 5432
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc1_cidr
}

resource "aws_vpc_security_group_ingress_rule" "redis_from_vpc1" {
  security_group_id = var.vpc3_sg_redis_id
  description       = "Redis from VPC1 backend pods"
  from_port         = 6379
  to_port           = 6379
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc1_cidr
}

# 테스트용: VPC1 -> VPC3 Bastion (22포트) 허용
resource "aws_vpc_security_group_ingress_rule" "bastion_from_vpc1" {
  security_group_id = var.vpc3_sg_bastion_id
  description       = "SSH from VPC1 for testing"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc1_cidr
}

#========================================
# VPC Peering Connection (VPC1 <-> VPC2)
#========================================
resource "aws_vpc_peering_connection" "vpc1_to_vpc2" {
  vpc_id        = var.vpc1_id
  peer_vpc_id   = var.vpc2_id
  peer_owner_id = local.peer_owner_id

  auto_accept = true

  tags = {
    Name = "${var.prefix}-vpc1-to-vpc2"
    Side = "both"
  }
}

resource "aws_vpc_peering_connection_options" "vpc1_to_vpc2" {
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }
}

#========================================
# Route Table Entries - VPC1 -> VPC2
#========================================
resource "aws_route" "vpc1_public_to_vpc2" {
  route_table_id            = var.vpc1_public_route_table_id
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
}

resource "aws_route" "vpc1_private_to_vpc2" {
  route_table_id            = var.vpc1_private_route_table_id
  destination_cidr_block    = var.vpc2_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
}

#========================================
# Route Table Entries - VPC2 -> VPC1
#========================================
resource "aws_route" "vpc2_public_to_vpc1" {
  route_table_id            = var.vpc2_public_route_table_id
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
}

resource "aws_route" "vpc2_private_to_vpc1" {
  route_table_id            = var.vpc2_private_route_table_id
  destination_cidr_block    = var.vpc1_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc1_to_vpc2.id
}