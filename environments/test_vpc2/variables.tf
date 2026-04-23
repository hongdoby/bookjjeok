# vpc2_onprem 모듈에 필요한 변수 추가

variable "vpc_cidr" {
  default = "10.1.0.0/16"
}

variable "cluster_name" {
  default = "bookjjeok-cloud-k8s"
}

variable "azs" {
  type    = list(string)
  default = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]
}

variable "public_subnet_2a_cidr" {
  default = "10.1.0.0/22"
}

variable "public_subnet_2b_cidr" {
  default = "10.1.4.0/22"
}

variable "public_subnet_2c_cidr" {
  default = "10.1.8.0/22"
}

variable "private_subnet_2a_cidr" {
  default = "10.1.16.0/22"
}

variable "private_subnet_2b_cidr" {
  default = "10.1.20.0/22"
}

variable "private_subnet_2c_cidr" {
  default = "10.1.24.0/22"
}

variable "nat_instance_ami" {
  # Amazon Linux 2 AMI (ap-northeast-2)
  default = "ami-04cebc8d6c4f297a3"
}

variable "nat_instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  # 본인 키페어 이름으로 교체!
  default = "bookjjeok-yuna-key-pair"
}

variable "vpc3_vpc_id" {
  default = "vpc-0c7d25517da97032e"
}

variable "vpc3_cidr" {
  default = "10.2.0.0/16"
}