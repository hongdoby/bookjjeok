########################################
# ① DATA SOURCES
########################################

data "aws_caller_identity" "current" {}

data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-kernel-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

########################################
# LOCALS
########################################

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  az_short    = [for az in var.azs : substr(az, -1, 1)]
  peer_owner_id = (
    var.vpc1_owner_account_id != ""
    ? var.vpc1_owner_account_id
    : data.aws_caller_identity.current.account_id
  )
}

########################################
# ② VPC
########################################

resource "aws_vpc" "vpc3" {
  cidr_block           = var.vpc3_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${local.name_prefix}-vpc3" }
}

########################################
# ② INTERNET GATEWAY
########################################

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-vpc3-igw" }
}

########################################
# ② 퍼블릭 서브넷 × 1 (AZ-a)
########################################

resource "aws_subnet" "public" {
  count = 2

  vpc_id                  = aws_vpc.vpc3.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-vpc3-pub-${local.az_short[count.index]}"
    Tier = "public"
  }
}

########################################
# ② 프라이빗 서브넷 × 2 (RDS/ElastiCache AWS 제약상 2개 유지)
########################################

resource "aws_subnet" "private" {
  count = 2

  vpc_id            = aws_vpc.vpc3.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.azs[count.index]

  tags = {
    Name = "${local.name_prefix}-vpc3-priv-${local.az_short[count.index]}"
    Tier = "private"
  }
}

########################################
# ③ EIP FOR NAT GATEWAY × 1
########################################

resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"

  tags = { Name = "${local.name_prefix}-vpc3-nat-eip-${local.az_short[count.index]}" }
}

########################################
# ③ NAT GATEWAY × 1
########################################

resource "aws_nat_gateway" "nat" {
  count = 1

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = { Name = "${local.name_prefix}-vpc3-nat-${local.az_short[count.index]}" }

  depends_on = [aws_internet_gateway.igw]
}

########################################
# ③ 퍼블릭 라우트 테이블 (1개)
########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-vpc3-pub-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

########################################
# ③ 프라이빗 라우트 테이블 × 1
########################################

resource "aws_route_table" "private" {
  count  = 1
  vpc_id = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-vpc3-priv-rt-${local.az_short[count.index]}" }
}

resource "aws_route" "private_nat" {
  count = 1

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[0].id
}

resource "aws_route_table_association" "private" {
  count = 1

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

########################################
# ④ SECURITY GROUP — Bastion
########################################

resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-"
  description = "Bastion SSH access"
  vpc_id      = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-bastion-sg" }

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  security_group_id = aws_security_group.bastion.id
  description       = "SSH from allowed CIDRs"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.allowed_ssh_cidrs[0]
}

resource "aws_vpc_security_group_ingress_rule" "bastion_icmp_from_vpc2" {
  security_group_id = aws_security_group.bastion.id
  description       = "ICMP from VPC2"
  from_port         = -1
  to_port           = -1
  ip_protocol       = "icmp"
  cidr_ipv4         = "10.1.0.0/16"
}

resource "aws_vpc_security_group_egress_rule" "bastion_all" {
  security_group_id = aws_security_group.bastion.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########################################
# ④ SECURITY GROUP — ALB
########################################

resource "aws_security_group" "alb" {
  name_prefix = "${local.name_prefix}-alb-"
  description = "ALB inbound HTTP/HTTPS"
  vpc_id      = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-alb-sg" }

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
resource "aws_iam_service_linked_role" "rds" {
  aws_service_name = "rds.amazonaws.com"
}

########################################
# ④ SECURITY GROUP — RDS Proxy
########################################

resource "aws_security_group" "rds_proxy" {
  name_prefix = "${local.name_prefix}-rds-proxy-"
  description = "RDS Proxy access"
  vpc_id      = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-rds-proxy-sg" }

  lifecycle { create_before_destroy = true }
}

# VPC1 올라오면 주석 해제
# resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_vpc1" {
#   security_group_id = aws_security_group.rds_proxy.id
#   description       = "PostgreSQL from VPC1 backend pods"
#   from_port         = 5432
#   to_port           = 5432
#   ip_protocol       = "tcp"
#   cidr_ipv4         = var.vpc1_cidr
# }

resource "aws_vpc_security_group_ingress_rule" "rds_proxy_from_bastion" {
  security_group_id            = aws_security_group.rds_proxy.id
  description                  = "PostgreSQL from Bastion"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "rds_proxy_all" {
  security_group_id = aws_security_group.rds_proxy.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########################################
# ④ SECURITY GROUP — RDS
########################################

resource "aws_security_group" "rds" {
  name_prefix = "${local.name_prefix}-rds-"
  description = "RDS PostgreSQL access"
  vpc_id      = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-rds-sg" }

  lifecycle { create_before_destroy = true }
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_proxy" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from RDS Proxy"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.rds_proxy.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_bastion" {
  security_group_id            = aws_security_group.rds.id
  description                  = "PostgreSQL from Bastion"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "rds_all" {
  security_group_id = aws_security_group.rds.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########################################
# ④ SECURITY GROUP — ElastiCache Redis
########################################

resource "aws_security_group" "redis" {
  name_prefix = "${local.name_prefix}-redis-"
  description = "ElastiCache Redis access"
  vpc_id      = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-redis-sg" }

  lifecycle { create_before_destroy = true }
}

# VPC1 올라오면 주석 해제
# resource "aws_vpc_security_group_ingress_rule" "redis_from_vpc1" {
#   security_group_id = aws_security_group.redis.id
#   description       = "Redis from VPC1 backend pods"
#   from_port         = 6379
#   to_port           = 6379
#   ip_protocol       = "tcp"
#   cidr_ipv4         = var.vpc1_cidr
# }

resource "aws_vpc_security_group_ingress_rule" "redis_from_bastion" {
  security_group_id            = aws_security_group.redis.id
  description                  = "Redis from Bastion"
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "redis_all" {
  security_group_id = aws_security_group.redis.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########################################
# ⑤ BASTION EC2 × 1 (AZ-a)
########################################

resource "aws_instance" "bastion" {
  count = 1

  ami                    = data.aws_ami.al2023.id
  instance_type          = var.bastion_instance_type
  key_name               = var.bastion_key_name
  subnet_id              = aws_subnet.public[count.index].id
  vpc_security_group_ids = [aws_security_group.bastion.id]


  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.bastion_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = { Name = "${local.name_prefix}-bastion-${local.az_short[count.index]}" }
}

resource "aws_eip" "bastion" {
  count  = 1
  domain = "vpc"

  tags = { Name = "${local.name_prefix}-bastion-eip-${local.az_short[count.index]}" }
}

resource "aws_eip_association" "bastion" {
  count = 1

  instance_id   = aws_instance.bastion[count.index].id
  allocation_id = aws_eip.bastion[count.index].id
}

########################################
# ⑥ ALB (퍼블릭 서브넷 1개)
########################################

resource "aws_lb" "main" {
  name               = "${local.name_prefix}-vpc3-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = { Name = "${local.name_prefix}-vpc3-alb" }
}

resource "aws_lb_target_group" "default" {
  name        = "${local.name_prefix}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc3.id
  target_type = "ip"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-vpc3-default-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.default.arn
  }

  tags = { Name = "${local.name_prefix}-vpc3-http-listener" }
}

########################################
# ⑦ RDS — 서브넷 그룹
########################################

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-vpc3-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name_prefix}-vpc3-db-subnet" }
}

########################################
# ⑦ RDS — 파라미터 그룹
########################################

resource "aws_db_parameter_group" "pg15" {
  name   = "${local.name_prefix}-vpc3-pg15-params"
  family = "postgres15"

  parameter {
    name  = "lc_messages"
    value = "en_US.UTF-8"
  }

  parameter {
    name         = "log_statement"
    value        = "ddl"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = { Name = "${local.name_prefix}-vpc3-pg15-params" }
}

########################################
# ⑦ RDS — PostgreSQL 15 Single-AZ
########################################

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-vpc3-pg"

  engine               = "postgres"
  engine_version       = "15"
  instance_class       = var.db_instance_class
  parameter_group_name = aws_db_parameter_group.pg15.name

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_allocated_storage * 2
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  multi_az               = false
  publicly_accessible    = false

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  backup_retention_period = 7
  backup_window           = "18:00-19:00"
  maintenance_window      = "sun:19:00-sun:20:00"

  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-vpc3-pg-final"
  deletion_protection       = true
  copy_tags_to_snapshot     = true

  tags = { Name = "${local.name_prefix}-vpc3-pg" }
}

########################################
# ⑧ RDS PROXY — Secrets Manager
########################################

resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${local.name_prefix}-vpc3-db-credentials"

  tags = { Name = "${local.name_prefix}-vpc3-db-credentials" }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = 5432
    dbname   = var.db_name
  })
}

########################################
# ⑧ RDS PROXY — IAM Role
########################################

data "aws_iam_policy_document" "rds_proxy_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_proxy" {
  name               = "${local.name_prefix}-vpc3-rds-proxy-role"
  assume_role_policy = data.aws_iam_policy_document.rds_proxy_assume.json

  tags = { Name = "${local.name_prefix}-vpc3-rds-proxy-role" }
}

data "aws_iam_policy_document" "rds_proxy_secret" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [aws_secretsmanager_secret.db_credentials.arn]
  }
}

resource "aws_iam_role_policy" "rds_proxy_secret" {
  name   = "read-db-secret"
  role   = aws_iam_role.rds_proxy.id
  policy = data.aws_iam_policy_document.rds_proxy_secret.json
}

########################################
# ⑧ RDS PROXY
########################################

resource "aws_db_proxy" "main" {
  name                   = "${local.name_prefix}-vpc3-pg-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy.arn
  vpc_subnet_ids         = aws_subnet.private[*].id
  vpc_security_group_ids = [aws_security_group.rds_proxy.id]

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
  }

  tags = { Name = "${local.name_prefix}-vpc3-pg-proxy" }
}

resource "aws_db_proxy_default_target_group" "main" {
  db_proxy_name = aws_db_proxy.main.name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "main" {
  db_proxy_name          = aws_db_proxy.main.name
  target_group_name      = aws_db_proxy_default_target_group.main.name
  db_instance_identifier = aws_db_instance.main.identifier
}

########################################
# ⑨ ELASTICACHE — 서브넷 그룹
########################################

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-vpc3-redis-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = { Name = "${local.name_prefix}-vpc3-redis-subnet" }
}

########################################
# ⑨ ELASTICACHE — Redis Single 노드
########################################

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${local.name_prefix}-vpc3-redis"
  description          = "Book Exchange Redis cluster"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = 1
  automatic_failover_enabled = false
  multi_az_enabled           = false

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  maintenance_window       = "sun:19:00-sun:20:00"
  snapshot_retention_limit = 3
  snapshot_window          = "18:00-19:00"

  tags = { Name = "${local.name_prefix}-vpc3-redis" }
}

########################################
# ⑩ VPC PEERING — VPC1 올라오면 주석 해제
########################################

# resource "aws_vpc_peering_connection" "vpc3_to_vpc1" {
#   vpc_id        = aws_vpc.vpc3.id
#   peer_vpc_id   = var.vpc1_id
#   peer_owner_id = local.peer_owner_id
#   peer_region   = var.aws_region
#
#   auto_accept = false
#
#   tags = {
#     Name = "${local.name_prefix}-vpc3-to-vpc1"
#     Side = "requester"
#   }
# }
#
# resource "aws_vpc_peering_connection_accepter" "vpc1_accept" {
#   count = var.vpc1_owner_account_id == "" ? 1 : 0
#
#   vpc_peering_connection_id = aws_vpc_peering_connection.vpc3_to_vpc1.id
#   auto_accept               = true
#
#   tags = {
#     Name = "${local.name_prefix}-vpc1-accept-vpc3"
#     Side = "accepter"
#   }
# }
#
# resource "aws_route" "public_to_vpc1" {
#   route_table_id            = aws_route_table.public.id
#   destination_cidr_block    = var.vpc1_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.vpc3_to_vpc1.id
# }
#
# resource "aws_route" "private_to_vpc1" {
#   count = 2
#
#   route_table_id            = aws_route_table.private[count.index].id
#   destination_cidr_block    = var.vpc1_cidr
#   vpc_peering_connection_id = aws_vpc_peering_connection.vpc3_to_vpc1.id
# }

########################################
# VPC2 Peering 라우트
########################################

resource "aws_route" "public_to_vpc2" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = "pcx-002f6a13e30b25a62"
}

resource "aws_route" "private_to_vpc2" {
  route_table_id            = aws_route_table.private[0].id
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = "pcx-002f6a13e30b25a62"
}

########################################
# SECURITY GROUP — Monitoring
########################################

resource "aws_security_group" "monitoring" {
  name_prefix = "${local.name_prefix}-monitoring-"
  description = "Prometheus + Grafana access"
  vpc_id      = aws_vpc.vpc3.id

  tags = { Name = "${local.name_prefix}-monitoring-sg" }

  lifecycle { create_before_destroy = true }
}

# Grafana 대시보드 (3000)
resource "aws_vpc_security_group_ingress_rule" "monitoring_grafana" {
  security_group_id = aws_security_group.monitoring.id
  description       = "Grafana from Bastion"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

# Prometheus (9090)
resource "aws_vpc_security_group_ingress_rule" "monitoring_prometheus" {
  security_group_id = aws_security_group.monitoring.id
  description       = "Prometheus from Bastion"
  from_port         = 9090
  to_port           = 9090
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

# VPC2에서 Prometheus scrape 허용 (9100 Node Exporter)
resource "aws_vpc_security_group_ingress_rule" "monitoring_from_vpc2" {
  security_group_id = aws_security_group.monitoring.id
  description       = "Node Exporter from VPC2"
  from_port         = 9100
  to_port           = 9100
  ip_protocol       = "tcp"
  cidr_ipv4         = "10.1.0.0/16"
}

# SSH from Bastion
resource "aws_vpc_security_group_ingress_rule" "monitoring_ssh" {
  security_group_id = aws_security_group.monitoring.id
  description       = "SSH from Bastion"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

resource "aws_vpc_security_group_egress_rule" "monitoring_all" {
  security_group_id = aws_security_group.monitoring.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

########################################
# Monitoring EC2 (Prometheus + Grafana)
########################################

resource "aws_instance" "monitoring" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.monitoring_instance_type
  key_name               = var.monitoring_key_name
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.monitoring.id]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.monitoring_volume_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = { Name = "${local.name_prefix}-monitoring" }
}

resource "aws_eip" "monitoring" {
  domain = "vpc"
  tags   = { Name = "${local.name_prefix}-monitoring-eip" }
}

resource "aws_eip_association" "monitoring" {
  instance_id   = aws_instance.monitoring.id
  allocation_id = aws_eip.monitoring.id
}