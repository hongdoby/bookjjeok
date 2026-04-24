# ==========================================
# EKS 클러스터 및 워커 노드 구성
# ==========================================
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  # 클러스터를 배치할 VPC와, 컨트롤플레인/워커노드가 통신할 Subnet 지정
  vpc_id = aws_vpc.this.id
  subnet_ids = [
    aws_subnet.private_a.id,
    aws_subnet.private_b.id
  ]
  
  # 보안 그룹 등 통신을 위해 Private 접근은 기본 허용이며, 외부(로컬 PC)에서 쿠버네티스 API(kubectl) 연결을 위해 Public 도 허용해둡니다.
  cluster_endpoint_public_access = true

  # [추가] 클러스터 생성자(현재 테라폼 실행 계정)에게 관리자 권한 부여
  authentication_mode                         = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  # ==========================================
  # Managed Node Groups (워커 노드)
  # ==========================================
  eks_managed_node_groups = {
    bookjjeok_workers = {
      # 워커 노드 개수: 2개로 요청하셨으므로 기본 2개 구동
      min_size     = 2
      max_size     = 5
      desired_size = 2

      # 요청하신 사양: Large 규격 (t3.large)
      instance_types = ["t3.large"]
      
      labels = {
        role = "worker"
      }
    }
  }

  # ArgoCD 인스턴스 Role을 클러스터 관리자로 등록 (Access Entry)
  access_entries = var.argocd_role_arn != "" ? {
    argocd_role = {
      principal_arn = var.argocd_role_arn
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  } : {}

  tags = {
    Environment = "prod-cloud"
  }
}
