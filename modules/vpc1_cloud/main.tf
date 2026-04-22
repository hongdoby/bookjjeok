# ==========================================
# 1. VPC 설정 (프로덕션 클라우드)
# ==========================================
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.prefix}-main"
  }
}

# ==========================================
# 2. Subnet 구성
# ==========================================
# Public Subnets (AZ-a, AZ-b) 
# ※ 주의: AWS ALB를 프로비저닝하려면 최소 2개의 가용 영역에 Public Subnet이 필요하므로 문서를 보강하여 AZ-b에도 Public을 추가합니다. (10.0.0.0/22, 10.0.4.0/22 등 CIDR 조정 가능)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.0.0/23" # 기존 10.0.0.0/22를 분할하여 AZ에 할당
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-public-a"
    "kubernetes.io/role/elb" = "1" # EKS 외부 로드밸런서(ALB) 태그
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.2.0/23"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-public-b"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnets (아키텍처 문서 참고하여 구성)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.4.0/22"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                              = "${var.prefix}-private-a"
    "kubernetes.io/role/internal-elb" = "1" # EKS 내부 로드밸런서 태그
  }
}

resource "aws_subnet" "private_b1" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.8.0/22"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name                              = "${var.prefix}-private-b1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_b2" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.12.0/22"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name                              = "${var.prefix}-private-b2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# ==========================================
# 3. IGW 및 NAT Gateway
# ==========================================
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

resource "aws_eip" "nat" {
  # vpc = true (최신 버전은 deprecated, 생략 허용)
  domain = "vpc"
  
  tags = {
    Name = "${var.prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id # AZ-a 퍼블릭 서브넷에 배치

  tags = {
    Name = "${var.prefix}-nat-gw"
  }

  depends_on = [aws_internet_gateway.this]
}

# ==========================================
# 4. Route Tables
# ==========================================
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.prefix}-rt-public"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.prefix}-rt-private"
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b1" {
  subnet_id      = aws_subnet.private_b1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b2" {
  subnet_id      = aws_subnet.private_b2.id
  route_table_id = aws_route_table.private.id
}
