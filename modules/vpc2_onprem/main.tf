# ─── VPC ───────────────────────────────────────────
resource "aws_vpc" "vpc2" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "bookjjeok-cloud-vpc2" }
}

# ─── IGW ───────────────────────────────────────────
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc2.id
  tags   = { Name = "bookjjeok-cloud-igw" }
}

# ─── 퍼블릭 서브넷 ──────────────────────────────────
resource "aws_subnet" "public_2a" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = var.public_subnet_2a_cidr
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true
  tags = { Name = "bookjjeok-cloud-public-2a" }
}

resource "aws_subnet" "public_2b" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = var.public_subnet_2b_cidr
  availability_zone       = var.azs[1]
  map_public_ip_on_launch = true
  tags = { Name = "bookjjeok-cloud-public-2b" }
}

resource "aws_subnet" "public_2c" {
  vpc_id                  = aws_vpc.vpc2.id
  cidr_block              = var.public_subnet_2c_cidr
  availability_zone       = var.azs[2]
  map_public_ip_on_launch = true
  tags = { Name = "bookjjeok-cloud-public-2c" }
}

# ─── 프라이빗 서브넷 ────────────────────────────────
resource "aws_subnet" "private_2a" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.private_subnet_2a_cidr
  availability_zone = var.azs[0]
  tags = {
    Name                                        = "bookjjeok-cloud-private-2a"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private_2b" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.private_subnet_2b_cidr
  availability_zone = var.azs[1]
  tags = {
    Name                                        = "bookjjeok-cloud-private-2b"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_subnet" "private_2c" {
  vpc_id            = aws_vpc.vpc2.id
  cidr_block        = var.private_subnet_2c_cidr
  availability_zone = var.azs[2]
  tags = {
    Name                                        = "bookjjeok-cloud-private-2c"
    "kubernetes.io/role/internal-elb"           = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# ─── NAT Instance SG ───────────────────────────────
resource "aws_security_group" "nat_sg" {
  name   = "bookjjeok-cloud-nat-sg"
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc3_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bookjjeok-cloud-nat-sg" }
}

# ─── NAT Instance ──────────────────────────────────
resource "aws_instance" "nat_instance" {
  ami                    = var.nat_instance_ami
  instance_type          = var.nat_instance_type
  subnet_id              = aws_subnet.public_2a.id
  key_name               = var.key_name
  source_dest_check      = false
  vpc_security_group_ids = [aws_security_group.nat_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    IFACE=$(ip route | grep default | awk '{print $5}')
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    iptables -t nat -A POSTROUTING -o $IFACE -j MASQUERADE
    apt-get install -y iptables-persistent
    netfilter-persistent save
  EOF

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
  }

  tags = { Name = "bookjjeok-cloud-nat-instance" }
}

# ─── 라우팅 테이블: 퍼블릭 ──────────────────────────
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = { Name = "bookjjeok-cloud-public-rt" }
}

resource "aws_route_table_association" "pub_2a" {
  subnet_id      = aws_subnet.public_2a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_2b" {
  subnet_id      = aws_subnet.public_2b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "pub_2c" {
  subnet_id      = aws_subnet.public_2c.id
  route_table_id = aws_route_table.public_rt.id
}

# ─── VPC Peering (vpc2 ↔ vpc3) ─────────────────────
resource "aws_vpc_peering_connection" "vpc2_to_vpc3" {
  vpc_id      = aws_vpc.vpc2.id
  peer_vpc_id = var.vpc3_vpc_id
  auto_accept = true

  tags = { Name = "bookjjeok-cloud-pcx-vpc2-vpc3" }
}

# ─── 라우팅 테이블: 프라이빗 ──────────────────────────
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc2.id

  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  }

  route {
    cidr_block                = var.vpc3_cidr
    vpc_peering_connection_id = aws_vpc_peering_connection.vpc2_to_vpc3.id
  }

  tags = { Name = "bookjjeok-cloud-private-rt" }
}

resource "aws_route_table_association" "priv_2a" {
  subnet_id      = aws_subnet.private_2a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "priv_2b" {
  subnet_id      = aws_subnet.private_2b.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "priv_2c" {
  subnet_id      = aws_subnet.private_2c.id
  route_table_id = aws_route_table.private_rt.id
}

# ─── Security Group: K8s 노드 ───────────────────────
resource "aws_security_group" "k8s_sg" {
  name   = "bookjjeok-cloud-k8s-sg"
  vpc_id = aws_vpc.vpc2.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc3_cidr]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bookjjeok-cloud-k8s-sg" }
}

# ─── EC2: Control Plane (AZ별 1개씩, 총 3개) ────────
resource "aws_instance" "control_plane_2a" {
  ami                    = var.nat_instance_ami
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private_2a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name = "bookjjeok-cloud-control-plane-2a"
    Role = "control-plane"
  }
}

resource "aws_instance" "control_plane_2b" {
  ami                    = var.nat_instance_ami
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private_2b.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name = "bookjjeok-cloud-control-plane-2b"
    Role = "control-plane"
  }
}

resource "aws_instance" "control_plane_2c" {
  ami                    = var.nat_instance_ami
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.private_2c.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name = "bookjjeok-cloud-control-plane-2c"
    Role = "control-plane"
  }
}

# ─── EC2: Worker Node (AZ별 1개씩, 총 3개) ──────────
resource "aws_instance" "worker_2a" {
  ami                    = var.nat_instance_ami
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.private_2a.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name = "bookjjeok-cloud-worker-2a"
    Role = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_instance" "worker_2b" {
  ami                    = var.nat_instance_ami
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.private_2b.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name = "bookjjeok-cloud-worker-2b"
    Role = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_instance" "worker_2c" {
  ami                    = var.nat_instance_ami
  instance_type          = "t3.large"
  subnet_id              = aws_subnet.private_2c.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
  }

  tags = {
    Name = "bookjjeok-cloud-worker-2c"
    Role = "worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_eip" "nat_eip" {
  instance = aws_instance.nat_instance.id
  domain   = "vpc"
  tags     = { Name = "bookjjeok-cloud-nat-eip" }
}