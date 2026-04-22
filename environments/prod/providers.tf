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
  
  # 공통적으로 모든 리소스에 태그 적용
  default_tags {
    tags = {
      Project     = "bookjjeok-cloud"
      Environment = "prod"
      ManagedBy   = "Terraform"
    }
  }
}
