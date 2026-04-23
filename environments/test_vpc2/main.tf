module "vpc2_onprem" {
  source = "../../modules/vpc2_onprem"

  vpc_cidr               = var.vpc_cidr
  cluster_name           = var.cluster_name
  azs                    = var.azs

  public_subnet_2a_cidr  = var.public_subnet_2a_cidr
  public_subnet_2b_cidr  = var.public_subnet_2b_cidr
  public_subnet_2c_cidr  = var.public_subnet_2c_cidr

  private_subnet_2a_cidr = var.private_subnet_2a_cidr
  private_subnet_2b_cidr = var.private_subnet_2b_cidr
  private_subnet_2c_cidr = var.private_subnet_2c_cidr

  nat_instance_ami  = var.nat_instance_ami
  nat_instance_type = var.nat_instance_type
  key_name          = var.key_name
  vpc3_vpc_id       = var.vpc3_vpc_id
  vpc3_cidr         = var.vpc3_cidr
}