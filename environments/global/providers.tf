provider "aws" {
  region = "ap-northeast-2"
}

# CloudFront 인증서(ACM) 생성을 위해 반드시 필요한 us-east-1 프로바이더
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
