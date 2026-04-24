data "aws_vpc" "vpc3" {
  filter {
    name   = "tag:Name"
    values = ["book-exchange-prod-vpc3"]
  }
}

data "aws_route_table" "vpc3_public" {
  vpc_id = data.aws_vpc.vpc3.id
  filter {
    name   = "tag:Name"
    values = ["book-exchange-prod-vpc3-pub-rt"]
  }
}

data "aws_route_tables" "vpc3_private" {
  vpc_id = data.aws_vpc.vpc3.id
  filter {
    name   = "tag:Name"
    values = ["book-exchange-prod-vpc3-priv-rt-*"]
  }
}

data "aws_security_group" "rds_proxy" {
  vpc_id = data.aws_vpc.vpc3.id
  filter {
    name   = "tag:Name"
    values = ["book-exchange-prod-rds-proxy-sg"]
  }
}

data "aws_security_group" "redis" {
  vpc_id = data.aws_vpc.vpc3.id
  filter {
    name   = "tag:Name"
    values = ["book-exchange-prod-redis-sg"]
  }
}

data "aws_security_group" "bastion" {
  vpc_id = data.aws_vpc.vpc3.id
  filter {
    name   = "tag:Name"
    values = ["book-exchange-prod-bastion-sg"]
  }
}

module "vpc1_cloud" {
  source = "../../modules/vpc1_cloud"

  vpc_cidr     = var.vpc1_cidr
  prefix       = var.vpc1_prefix
  cluster_name = var.vpc1_cluster_name
}

module "networking" {
  source = "../../modules/networking"

  prefix = var.vpc1_prefix

  # VPC1 Info
  vpc1_id                     = module.vpc1_cloud.vpc_id
  vpc1_cidr                   = var.vpc1_cidr
  vpc1_public_route_table_id  = module.vpc1_cloud.public_route_table_id
  vpc1_private_route_table_id = module.vpc1_cloud.private_route_table_id

  # VPC3 Info (via Data Sources)
  vpc3_id                      = data.aws_vpc.vpc3.id
  vpc3_cidr                    = data.aws_vpc.vpc3.cidr_block
  vpc3_public_route_table_id   = data.aws_route_table.vpc3_public.id
  vpc3_private_route_table_ids = data.aws_route_tables.vpc3_private.ids
  vpc3_sg_rds_proxy_id         = data.aws_security_group.rds_proxy.id
  vpc3_sg_redis_id             = data.aws_security_group.redis.id
  vpc3_sg_bastion_id           = data.aws_security_group.bastion.id
}
