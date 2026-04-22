variable "vpc_cidr" {}
variable "cluster_name" {}

variable "public_subnet_2a_cidr" {}
variable "public_subnet_2b_cidr" {}
variable "public_subnet_2c_cidr" {}

variable "private_subnet_2a_cidr" {}
variable "private_subnet_2b_cidr" {}
variable "private_subnet_2c_cidr" {}

variable "azs" {
  type = list(string)
}

variable "nat_instance_ami" {}
variable "nat_instance_type" {
  default = "t3.micro"
}

variable "key_name" {}