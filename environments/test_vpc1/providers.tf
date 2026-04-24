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

provider "kubernetes" {
  # 로컬에서 성공한 kubeconfig를 직접 참조
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    # 로컬에서 성공한 kubeconfig를 직접 참조
    config_path = "~/.kube/config"
  }
}
