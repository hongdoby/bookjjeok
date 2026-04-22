module "vpc1_cloud" {
  source = "../../modules/vpc1_cloud"

  vpc_cidr     = var.vpc1_cidr
  prefix       = var.vpc1_prefix
  cluster_name = var.vpc1_cluster_name
}
