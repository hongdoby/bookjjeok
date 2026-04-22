module "vpc3_shared" {
  source = "../../modules/vpc3_shared"

  db_instance_class    = "db.t4g.micro"
  vpc3_cidr            = "10.2.0.0/16"
  azs                  = ["ap-northeast-2a", "ap-northeast-2b"]
  public_subnet_cidrs  = ["10.2.0.0/24", "10.2.1.0/24"]
  private_subnet_cidrs = ["10.2.2.0/24", "10.2.3.0/24"]
  vpc1_cidr            = "10.0.0.0/16"
  vpc1_id              = "vpc-00000000000000000"
  bastion_key_name     = "book-exchange-bastion-key"
  db_password          = ""               # 직접 입력
  tailscale_auth_key   = ""               # 직접 입력
}