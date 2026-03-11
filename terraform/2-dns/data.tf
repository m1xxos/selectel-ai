data "terraform_remote_state" "infra" {
  backend = "s3"

  config = {
    bucket     = "yc-terraform-m1xxos-state"
    key        = "0-infra/terraform.tfstate"
    region     = "ru-central1"
    access_key = var.s3_access_key
    secret_key = var.s3_secret_key

    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}
