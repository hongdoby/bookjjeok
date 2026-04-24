variable "cluster_name" {
  description = "EKS 클러스터 이름"
  type        = string
  default     = "bookjjeok-cloud-eks-cluster"
}

variable "argocd_role_arn" {
  description = "ArgoCD 인스턴스 IAM Role ARN (Access Entry 등록용)"
  type        = string
  default     = ""
}
