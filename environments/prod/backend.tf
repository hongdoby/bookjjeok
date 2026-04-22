terraform {
  backend "s3" {
    bucket         = "bookjjeok-cloud-s3-tfstate"         # 사용자님이 미리 생성해두신 S3 버킷명
    key            = "prod/terraform.tfstate"           # S3 내에 저장될 state 파일 경로
    region         = "ap-northeast-2"                   # 서울 리전
    encrypt        = true                               # 저장 시 암호화 활성화
    dynamodb_table = "bookjjeok-cloud-db-tfstate"         # Lock 기능에 사용할 DynamoDB 테이블
  }
}
