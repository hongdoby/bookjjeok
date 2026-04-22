terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "aws" {
  region = "ap-northeast-2"
  
  default_tags {
    tags = {
      Project     = "bookjjeok-cloud"
      Environment = "test_vpc1"
      ManagedBy   = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.vpc1_cloud.cluster_endpoint
  cluster_ca_certificate = base64decode(module.vpc1_cloud.cluster_certificate_authority_data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.vpc1_cloud.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  # Helm v3.x: kubernetes provider 설정을 자동으로 상속받음
}
