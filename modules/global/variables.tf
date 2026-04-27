variable "frontend_bucket_name" {
  description = "프론트엔드 정적 웹사이트 호스팅용 S3 버킷 이름 (글로벌 고유값)"
  type        = string
  default     = "bookjjeok-frontend"
}

variable "environment" {
  description = "환경 (예: dev, test, prod)"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "프로젝트 이름"
  type        = string
  default     = "bookjjeok"
}

variable "domain_name" {
  description = "사용할 기본 도메인 이름"
  type        = string
  default     = "bookjjeok.cloud"
}

variable "log_bucket_name" {
  description = "중앙 로그 저장용 S3 버킷 이름"
  type        = string
  default     = "bookjjeok-cloud-logs-s3"
}
