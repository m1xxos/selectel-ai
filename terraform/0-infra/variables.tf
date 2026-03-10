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
