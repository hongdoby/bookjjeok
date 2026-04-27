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
  
  # 클러스터 엔드포인트 설정 (VPC 내부 통신을 위해 Private 활성화 필수)
  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  # [추가] 클러스터 생성자(현재 테라폼 실행 계정)에게 관리자 권한 부여
  authentication_mode                         = "API_AND_CONFIG_MAP"
  enable_cluster_creator_admin_permissions = true

  # ==========================================
  # Managed Node Groups (상시 1대)
  # ==========================================
  eks_managed_node_groups = {
    bookjjeok_cloud_eks_nodegroup = {
      # IAM 역할 이름이 너무 길어지는 것을 방지하기 위해 직접 지정합니다.
      iam_role_use_name_prefix = false
      iam_role_name            = "bookjjeok-cloud-eks-worker-role"

      min_size     = 1
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.medium"] # 시스템용이므로 조금 낮춰도 됩니다.
      
      labels = {
        role = "system"
      }
    }
  }

  # Karpenter가 노드용 보안 그룹을 찾을 수 있도록 태그 추가
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  # ArgoCD 및 Karpenter Role을 클러스터 관리자로 등록 (Access Entry)
  access_entries = merge(
    var.argocd_role_arn != "" ? {
      argocd_role = {
        principal_arn = var.argocd_role_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    } : {},
    {
      # Karpenter 컨트롤러용 Access Entry
      karpenter_controller = {
        principal_arn = module.karpenter_controller_irsa_role.iam_role_arn
        policy_associations = {
          admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      },
      # [추가] 카펜터가 생성한 노드들이 클러스터에 합류할 수 있도록 허용
      karpenter_node = {
        principal_arn = aws_iam_role.karpenter_node.arn
        type          = "EC2_LINUX"
      }
    }
  )

  tags = {
    Environment = "prod-cloud"
  }
}
