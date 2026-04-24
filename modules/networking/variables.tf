variable "prefix" {
  type        = string
  description = "리소스 이름에 붙일 접두사"
  default     = "bookjjeok"
}

variable "aws_region" {
  type        = string
  default     = "ap-northeast-2"
}

variable "peer_owner_id" {
  type        = string
  description = "피어링 대상 AWS 계정 ID (비워두면 현재 계정)"
  default     = ""
}

#====================
# VPC1 정보
#====================
variable "vpc1_id" {
  type        = string
  description = "VPC1 ID"
}

variable "vpc1_cidr" {
  type        = string
  description = "VPC1 CIDR Block"
}

variable "vpc1_public_route_table_id" {
  type        = string
  description = "VPC1 Public Route Table ID"
}

variable "vpc1_private_route_table_id" {
  type        = string
  description = "VPC1 Private Route Table ID"
}

#====================
# VPC2 정보
#====================
variable "vpc2_id" {
  type        = string
  description = "VPC2 ID"
}

variable "vpc2_cidr" {
  type        = string
  description = "VPC2 CIDR Block"
}

variable "vpc2_public_route_table_id" {
  type        = string
  description = "VPC2 Public Route Table ID"
}

variable "vpc2_private_route_table_id" {
  type        = string
  description = "VPC2 Private Route Table ID"
}

#====================
# VPC3 정보
#====================
variable "vpc3_id" {
  type        = string
  description = "VPC3 ID"
}

variable "vpc3_cidr" {
  type        = string
  description = "VPC3 CIDR Block"
}

variable "vpc3_public_route_table_id" {
  type        = string
  description = "VPC3 Public Route Table ID"
}

variable "vpc3_private_route_table_ids" {
  type        = list(string)
  description = "VPC3 Private Route Table IDs"
}

variable "vpc3_sg_rds_proxy_id" {
  type        = string
  description = "VPC3 RDS Proxy Security Group ID"
}

variable "vpc3_sg_redis_id" {
  type        = string
  description = "VPC3 Redis Security Group ID"
}

variable "vpc3_sg_bastion_id" {
  type        = string
  description = "VPC3 Bastion Security Group ID"
}
