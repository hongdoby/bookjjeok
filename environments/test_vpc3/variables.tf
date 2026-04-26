variable "db_password" {
  type      = string
  sensitive = true
}

variable "project_name" {
  type    = string
  default = "bookjjeok"
}

variable "environment" {
  type    = string
  default = "cloud"
}

