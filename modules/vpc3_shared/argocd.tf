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

resource "aws_instance" "argocd" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.argocd_instance_type
  key_name               = var.bastion_key_name
  subnet_id              = aws_subnet.private[0].id # 퍼블릭이 아닌 프라이빗 서브넷 배치
  vpc_security_group_ids = [aws_security_group.argocd.id]

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

# 5. ArgoCD Ingress 구성 (Traefik 연동)
# SSL은 Traefik이 처리하므로 ArgoCD 서버 자체는 --insecure 모드로 동작하도록 패치
/usr/local/bin/kubectl patch deployment argocd-server -n argocd --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--insecure"}]'

cat <<'INGRESS' > /tmp/argocd-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              name: http
INGRESS
/usr/local/bin/kubectl apply -f /tmp/argocd-ingress.yaml

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
