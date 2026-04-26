# ==========================================
# 에러 로그 분석용 OpenSearch 도메인 설정
# ==========================================

# resource "aws_iam_service_linked_role" "opensearch" {
#   aws_service_name = "opensearchservice.amazonaws.com"
# }

data "aws_region" "current" {}

# 1. OpenSearch 전용 보안 그룹
resource "aws_security_group" "opensearch" {
  name        = "${local.name_prefix}-opensearch-sg"
  description = "Security group for OpenSearch Domain"
  vpc_id      = aws_vpc.vpc3.id

  # HTTPS (443) 포트 허용: VPC1, VPC2, VPC3 전체 대역
  ingress {
    description = "Allow HTTPS from VPC1, VPC2, VPC3"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr, var.vpc2_cidr, var.vpc3_cidr, "100.64.0.0/10"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-opensearch-sg"
  }
}

# 2. OpenSearch 도메인 생성
resource "aws_opensearch_domain" "logs" {
  domain_name    = "${local.name_prefix}-logs"
  engine_version = "OpenSearch_2.11" # 최신 안정 버전

  cluster_config {
    instance_type = "t3.small.search" # 저렴한 테스트용 타입
    instance_count = 1                # 단일 노드 구성 (비용 절감)
  }

  vpc_options {
    subnet_ids         = [aws_subnet.private[0].id] # VPC3의 프라이빗 서브넷에 배치
    security_group_ids = [aws_security_group.opensearch.id]
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    volume_type = "gp3"
  }

  # 액세스 정책 (기본적으로 IAM 기반 접근 허용)
  access_policies = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "es:*",
      "Resource": "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${local.name_prefix}-logs/*"
    }
  ]
}
POLICY

  # 보안 설정을 위해 노드 간 통신 암호화 및 데이터 암호화 활성화
  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  tags = {
    Name = "${local.name_prefix}-logs"
  }
}

# 3. 출력값 (Fluent Bit 설정 시 필요)
output "opensearch_endpoint" {
  value = aws_opensearch_domain.logs.endpoint
}
