# ==========================================
# Frontend S3 Bucket (For CloudFront)
# ==========================================

# S3 버킷 생성 (CloudFront OAC 사용 예정이므로 정적 웹사이트 호스팅 기능은 비활성화합니다)
resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name

  tags = {
    Name        = var.frontend_bucket_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# 버킷 버전 관리 활성화 (안전한 배포 롤백을 위해)
resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 모든 퍼블릭 액세스 차단 (보안 모범 사례: 오직 CloudFront만 접근 가능하도록 설정)
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS 설정 (프론트엔드 API 호출 등을 위해 필요시 세팅)
resource "aws_s3_bucket_cors_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"] # 추후 도메인 확정 시 ["https://example.com"] 등으로 제한 권장
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# 기본 암호화 활성화
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ==========================================
# Outputs
# ==========================================

output "frontend_bucket_regional_domain_name" {
  description = "프론트엔드 S3 버킷 리전 도메인 (CloudFront Origin 설정용)"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}

# ==========================================
# 중앙 로그 저장용 S3 버킷 설정 (Fluent Bit 전용)
# ==========================================

resource "aws_s3_bucket" "logs" {
  bucket = var.log_bucket_name

  tags = {
    Name        = var.log_bucket_name
    Environment = var.environment
    Project     = var.project_name
  }
}

# 1. 버킷 버전 관리
resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 2. 기본 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 3. 퍼블릭 액세스 차단
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 4. 생명주기 관리 (90일 후 삭제)
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

output "log_bucket_id" {
  value = aws_s3_bucket.logs.id
}

output "log_bucket_arn" {
  value = aws_s3_bucket.logs.arn
}
