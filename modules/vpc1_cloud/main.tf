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
# Public Subnet (AZ-a)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.0.0/22"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-public-a"
    "kubernetes.io/role/elb" = "1" # EKS 외부 로드밸런서(ALB) 태그
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = "10.0.4.0/22"
  availability_zone       = "ap-northeast-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.prefix}-public-b"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private Subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.8.0/22"
  availability_zone = "ap-northeast-2a"

  tags = {
    Name                              = "${var.prefix}-private-a"
    "kubernetes.io/role/internal-elb" = "1" # EKS 내부 로드밸런서 태그
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.this.id
  cidr_block        = "10.0.12.0/22"
  availability_zone = "ap-northeast-2b"

  tags = {
    Name                              = "${var.prefix}-private-b"
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
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}
