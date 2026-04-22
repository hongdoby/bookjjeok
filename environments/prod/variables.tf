variable "vpc1_cidr" {
  description = "VPC1 (클라우드 환경) 네트워크 CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc1_prefix" {
  description = "VPC1 리소스에 사용할 접두사"
  type        = string
  default     = "bookjjeok-cloud-vpc1"
}

variable "vpc1_cluster_name" {
  description = "VPC1에 배포될 EKS 클러스터 이름"
  type        = string
  default     = "bookjjeok-cloud-eks-cluster"
}
