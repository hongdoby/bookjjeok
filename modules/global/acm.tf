# ==========================================
# ACM Certificate (us-east-1)
# ==========================================

# CloudFront용 ACM 인증서는 반드시 us-east-1 리전에 생성해야 합니다.
resource "aws_acm_certificate" "frontend" {
  provider                  = aws.us_east_1
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  tags = {
    Name        = "${var.project_name}-acm"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ACM 검증용 Route53 레코드 생성
# bookjjeok.cloud(루트)와 www.bookjjeok.cloud 는 서로 다른 CNAME을 생성하므로 중복 없이 단순하게 처리됩니다.
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  records         = [each.value.record]
  ttl             = 60
  allow_overwrite = true
}

# 인증서 발급 완료 대기
resource "aws_acm_certificate_validation" "frontend" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.frontend.arn
  validation_record_fqdns = [for record in aws_route53_record.acm_validation : record.fqdn]
}
