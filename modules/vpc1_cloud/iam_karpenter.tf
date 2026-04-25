# ==========================================
# Karpenter IAM Roles & Policies
# ==========================================

# 1. Karpenter Node Role (신규 노드들이 가질 권한)
resource "aws_iam_role" "karpenter_node" {
  name = "${var.prefix}-karpenter-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter_node_workernode" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.karpenter_node.name
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.karpenter_node.name
}

# EC2 인스턴스 프로파일 생성 (Karpenter 설정에서 사용됨)
resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.prefix}-karpenter-instance-profile"
  role = aws_iam_role.karpenter_node.name
}

# 2. Karpenter Controller Role (Karpenter 파드가 가질 권한 - IRSA)
module "karpenter_controller_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name                          = "${var.prefix}-karpenter-controller-role"
  attach_karpenter_controller_policy = true

  karpenter_controller_cluster_name = var.cluster_name
  # Karpenter가 사용할 노드 역할의 ARN을 정책에 포함시킵니다.
  karpenter_controller_node_iam_role_arns = [
    aws_iam_role.karpenter_node.arn
  ]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["karpenter:karpenter"]
    }
  }
}

# [추가] 인스턴스 프로파일 관리를 위한 추가 권한 (별도 정책 리소스로 정의)
resource "aws_iam_role_policy" "karpenter_controller_extra" {
  name = "${var.prefix}-karpenter-extra-policy"
  role = module.karpenter_controller_irsa_role.iam_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "KarpenterIAMActions"
        Effect = "Allow"
        Action = [
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromServiceLinkedRole",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:CreateServiceLinkedRole",
          "ec2:RunInstances",
          "ec2:CreateFleet",
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeImages",
          "ec2:DescribeImages",
          "ec2:DescribeSpotPriceHistory",
          "ec2:TerminateInstances",
          "ssm:GetParameter"
        ]
        Resource = "*"
      }
    ]
  })
}
