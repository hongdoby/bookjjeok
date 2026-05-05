variable "vpc_cidr" {
  description = "VPC1 (클라우드 환경) 네트워크 CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "prefix" {
  description = "리소스 이름 앞단에 붙을 프리픽스"
  type        = string
  default     = "bookjjeok-cloud-vpc1"
}

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
