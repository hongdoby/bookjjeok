terraform {
  backend "s3" {
    bucket         = "bookjjeok-cloud-s3-tfstate"
    key            = "test_vpc2/terraform.tfstate"
    region         = "ap-northeast-2"
    encrypt        = true
    dynamodb_table = "bookjjeok-cloud-db-tfstate"
  }
}
