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

variable "vpc1_cidr" {
  default = "10.0.0.0/16"
}

variable "vpc3_cidr" {
  default = "10.2.0.0/16"
}

variable "envoy_node_ip" {
  type        = string
  description = "Envoy Gateway 파드가 실행 중인 워커노드 IP"
  default     = "10.1.23.243"
}

variable "envoy_nodeport_https" {
  type        = string
  description = "Envoy Gateway HTTPS NodePort"
  default     = "32020"
}

variable "envoy_nodeport_http" {
  type        = string
  description = "Envoy Gateway HTTP NodePort"
  default     = "31664"
}