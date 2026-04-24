########################################
# 공통
########################################

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "book-exchange"
}

variable "environment" {
  description = "환경 (dev / staging / prod)"
  type        = string
  default     = "prod"
}

########################################
# VPC & 서브넷
########################################

variable "vpc3_cidr" {
  description = "VPC3 CIDR 블록"
  type        = string
  default     = "10.30.0.0/16"
}

variable "azs" {
  description = "사용할 가용영역 목록 (2개)"
  type        = list(string)
  default     = ["ap-northeast-2a", "ap-northeast-2c"]
}

variable "public_subnet_cidrs" {
  description = "퍼블릭 서브넷 CIDR (AZ 순서)"
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "프라이빗 서브넷 CIDR (AZ 순서)"
  type        = list(string)
  default     = ["10.30.11.0/24", "10.30.12.0/24"]
}

########################################
# VPC Peering (VPC1)
########################################

variable "vpc1_id" {
  description = "VPC1 ID (백엔드 파드가 있는 VPC)"
  type        = string
}

variable "vpc1_cidr" {
  description = "VPC1 CIDR 블록"
  type        = string
  default     = "10.10.0.0/16"
}

variable "vpc1_owner_account_id" {
  description = "VPC1 소유 AWS 계정 ID (같은 계정이면 빈 문자열)"
  type        = string
  default     = ""
}

########################################
# Bastion
########################################

variable "bastion_instance_type" {
  description = "Bastion 인스턴스 타입"
  type        = string
  default     = "t3.micro"
}

variable "bastion_volume_size" {
  description = "Bastion EBS 볼륨 크기 (GB)"
  type        = number
  default     = 30
}

variable "bastion_key_name" {
  description = "Bastion SSH 키페어 이름"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "Bastion SSH 접근 허용 CIDR 목록"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}



########################################
# RDS
########################################

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t4g.medium"
}

variable "db_allocated_storage" {
  description = "RDS 스토리지 크기 (GB)"
  type        = number
  default     = 30
}

variable "db_name" {
  description = "초기 데이터베이스 이름"
  type        = string
  default     = "bookexchange"
}

variable "db_username" {
  description = "RDS 마스터 유저명"
  type        = string
  default     = "dbadmin"
  sensitive   = true
}

variable "db_password" {
  description = "RDS 마스터 비밀번호"
  type        = string
  sensitive   = true
}

########################################
# ElastiCache Redis
########################################

variable "redis_node_type" {
  description = "ElastiCache Redis 노드 타입"
  type        = string
  default     = "cache.t4g.micro"
}

variable "redis_num_replicas" {
  description = "Redis 복제본 수 (primary 제외)"
  type        = number
  default     = 1
}