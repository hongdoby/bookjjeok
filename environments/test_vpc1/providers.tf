terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
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

data "aws_eks_cluster_auth" "cluster" {
  name = module.vpc1_cloud.cluster_name
}

provider "kubernetes" {
  host                   = module.vpc1_cloud.cluster_endpoint
  cluster_ca_certificate = base64decode(module.vpc1_cloud.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = module.vpc1_cloud.cluster_endpoint
    cluster_ca_certificate = base64decode(module.vpc1_cloud.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token
  }
}
