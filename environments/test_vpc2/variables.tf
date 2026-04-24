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
  default = "ami-04cebc8d6c4f297a3"
}

variable "nat_instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "bookjjeok-yuna-key-pair"
}

variable "vpc1_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc3_cidr" {
  default = "10.2.0.0/16"
}