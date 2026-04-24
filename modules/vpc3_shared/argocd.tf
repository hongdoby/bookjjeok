# ==========================================
# ArgoCD (K3s) Instance - Private Internal Setup
# ==========================================

variable "argocd_instance_type" {
  description = "ArgoCD (K3s) 인스턴스 타입"
  type        = string
  default     = "t3.medium"
}

resource "aws_security_group" "argocd" {
  name        = "${local.name_prefix}-argocd-sg"
  description = "Security group for ArgoCD instance (Private)"
  vpc_id      = aws_vpc.vpc3.id

  ingress {
    description = "SSH from Bastion / Internal"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc3_cidr, "100.64.0.0/10"]
  }

  ingress {
    description = "ArgoCD UI (HTTP via Traefik Ingress)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr, var.vpc3_cidr, "100.64.0.0/10"]
  }

  ingress {
    description = "ArgoCD UI (HTTPS via Traefik Ingress)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc1_cidr, var.vpc3_cidr, "100.64.0.0/10"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-argocd-sg"
  }
}

# ArgoCD 전용 IAM Role
resource "aws_iam_role" "argocd" {
  name = "${local.name_prefix}-argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-argocd-role"
  }
}

# EKS 클러스터 관리 권한 (Inline Policy)
resource "aws_iam_role_policy" "argocd_eks" {
  name = "${local.name_prefix}-argocd-eks-policy"
  role = aws_iam_role.argocd.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
          "iam:PassRole",
          "sts:AssumeRole"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# EC2 인스턴스 프로파일
resource "aws_iam_instance_profile" "argocd" {
  name = "${local.name_prefix}-argocd-instance-profile"
  role = aws_iam_role.argocd.name
}

resource "aws_instance" "argocd" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.argocd_instance_type
  key_name               = var.bastion_key_name
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.argocd.id]
  iam_instance_profile   = aws_iam_instance_profile.argocd.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
#!/bin/bash
set -ex

# 1. 패키지 업데이트
dnf update -y

# 2. K3s 설치 (기본 Traefik Ingress 활성화 유지)
curl -sfL https://get.k3s.io | sh -

# 3. K3s 준비 대기
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
until /usr/local/bin/kubectl get nodes; do sleep 2; done

# 4. ArgoCD 설치
/usr/local/bin/kubectl create namespace argocd
/usr/local/bin/kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 5. ArgoCD 서버 설정 고도화
# - SSL 리다이렉트 해제 (--insecure) 및 경로 기반 접속 설정 (--rootpath)
/usr/local/bin/kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--insecure"}, {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--rootpath"}, {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "/argocd"}]'

cat <<INGRESS_YAML | /usr/local/bin/kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: "traefik"
spec:
  rules:
  - http:
      paths:
      - path: /argocd
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: http
INGRESS_YAML

# 6. ec2-user가 kubectl을 바로 사용할 수 있도록 설정
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube
echo "export KUBECONFIG=/home/ec2-user/.kube/config" >> /home/ec2-user/.bashrc
EOF

  tags = {
    Name = "${local.name_prefix}-argocd"
  }
}

output "argocd_private_ip" {
  description = "ArgoCD 인스턴스의 Private IP (내부 통신용)"
  value       = aws_instance.argocd.private_ip
}

output "argocd_internal_url" {
  description = "ArgoCD 내부 접속 URL (HTTP/HTTPS)"
  value       = "http://${aws_instance.argocd.private_ip}"
}

# ==========================================
# ArgoCD ALB 설정 (Public Access)
# ==========================================

resource "aws_lb_target_group" "argocd" {
  name        = "${local.name_prefix}-argocd-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.vpc3.id
  target_type = "instance"

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200-399"
  }

  tags = { Name = "${local.name_prefix}-argocd-tg" }
}

resource "aws_lb_target_group_attachment" "argocd" {
  target_group_arn = aws_lb_target_group.argocd.arn
  target_id        = aws_instance.argocd.id
  port             = 80
}

resource "aws_vpc_security_group_ingress_rule" "argocd_from_alb" {
  security_group_id            = aws_security_group.argocd.id
  description                  = "Allow HTTP from ALB"
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id
}
