locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

remote_state {
  backend = "s3"
  config = {
    endpoint                    = "https://storage.yandexcloud.net"
    region                      = "ru-central1"
    bucket                      = local.env.locals.bucket
    key                         = "${path_relative_to_include()}/terraform.tfstate"
    access_key                  = local.env.locals.access_key
    secret_key                  = local.env.locals.secret_key
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
    skip_bucket_enforced_tls    = true
  }
  generate = {
    path      = "_backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "infisical" {
  path      = "_infisical.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    variable "infisical_id" {
      type      = string
      sensitive = true
    }

    variable "infisical_secret" {
      type      = string
      sensitive = true
    }

    locals {
      infisical_env_slug     = "prod"
      infisical_folder_path  = "/"
      infisical_workspace_id = "cc160c9f-8470-482f-a8da-350d68337f48"  # TODO: fill with Infisical workspace ID
    }

    provider "infisical" {
      host = "https://infisical.home.m1xxos.tech"
      auth = {
        universal = {
          client_id     = var.infisical_id
          client_secret = var.infisical_secret
        }
      }
    }
  EOF
}

inputs = {
  infisical_id     = local.env.locals.infisical_id
  infisical_secret = local.env.locals.infisical_secret
}
