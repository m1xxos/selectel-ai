variable "default_labels" {
  type = map(string)
  default = {
    "project"     = "ai"
    "environment" = "prod"
  }
}

variable "project_id" {
  type      = string
  sensitive = true
}

variable "region" {
  type    = string
  default = "ru-9"
}

variable "infisical_id" {
  type      = string
  sensitive = true
}

variable "infisical_secret" {
  type      = string
  sensitive = true
}
