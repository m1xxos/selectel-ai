terraform {
  backend "s3" {
    endpoint                    = "https://storage.yandexcloud.net"
    region                      = "ru-central1"
    bucket                      = var.bucket
    key                         = "selectel-ai.tfstate"
    access_key                  = var.access_key
    secret_key                  = var.secret_key
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
  required_providers {
    selectel = {
      source  = "selectel/selectel"
      version = "7.5.4"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.8.1"
    }
  }
}

provider "selectel" {
  auth_region = "ru-9"
  auth_url    = "https://cloud.api.selcloud.ru/identity/v3/"
}

provider "openstack" {
  auth_url  = "https://cloud.api.selcloud.ru/identity/v3"
  tenant_id = selectel_vpc_project_v2.ai_project.id
  user_name = selectel_iam_serviceuser_v1.ai_sa.name
  password  = selectel_iam_serviceuser_v1.ai_sa.password
  region    = "ru-9"
}
