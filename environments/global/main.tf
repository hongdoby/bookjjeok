module "global" {
  source = "../../modules/global"

  providers = {
    aws.us_east_1 = aws.us_east_1
  }

  # 도메인 이름 (필요시 여기서 덮어쓰기 가능, 기본값은 모듈 내 정의됨)
  # domain_name = "bookjjeok.cloud"
}

output "website_url" {
  value = module.global.website_url
}

output "cloudfront_domain_name" {
  value = module.global.cloudfront_domain_name
}

output "log_bucket_id" {
  value = module.global.log_bucket_id
}

output "log_bucket_arn" {
  value = module.global.log_bucket_arn
}
