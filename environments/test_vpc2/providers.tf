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
      Environment = "test_vpc2"
      ManagedBy   = "Terraform"
    }
  }
}
