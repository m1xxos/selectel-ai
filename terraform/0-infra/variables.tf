variable "access_key" {
  type      = string
  sensitive = true
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "bucket" {
  type      = string
  sensitive = true
}

variable "default_labels" {
  type = map(string)
  default = {
    "project"     = "ai"
    "environment" = "prod"
  }
}

variable "project_id" {
  sensitive = true
}

variable "region" {
  type = string
  default = "ru-9"
}
