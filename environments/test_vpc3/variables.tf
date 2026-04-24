# vpc3_shared 모듈에 필요한 변수 추가


variable "db_password" {
  type      = string
  sensitive = true
}

