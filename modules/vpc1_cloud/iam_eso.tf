# ==========================================
# External Secrets Operator를 위한 IAM Role (IRSA)
# ==========================================

module "eso_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.prefix}-eso-role"

  # Secrets Manager 및 Parameter Store 읽기 권한 정책 자동 연결
  attach_external_secrets_policy = true
  
  # 특정 Secret으로 권한을 제한하려면 아래 리스트에 ARN을 추가할 수 있습니다.
  # external_secrets_secrets_manager_arns = ["arn:aws:secretsmanager:ap-northeast-2:123456789012:secret:my-secret-*"]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = {
    Name = "${var.prefix}-eso-role"
  }
}

output "eso_role_arn" {
  description = "External Secrets Operator가 사용할 IAM Role ARN"
  value       = module.eso_irsa_role.iam_role_arn
}
